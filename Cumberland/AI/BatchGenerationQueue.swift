//
//  BatchGenerationQueue.swift
//  Cumberland
//
//  Created by Claude Code on 2/2/26.
//  ER-0017 Phase 1: Batch Image Generation Queue Management
//

import Foundation
import SwiftUI
import SwiftData
import OSLog

/// Manages batch image generation for multiple cards
/// Handles queuing, progress tracking, rate limiting, and error handling
@Observable
final class BatchGenerationQueue {

    // MARK: - Task Status

    /// Status of an individual batch generation task
    enum TaskStatus: Equatable {
        case queued
        case generating
        case completed(imageData: Data)
        case failed(error: String)
        case cancelled

        var isTerminal: Bool {
            switch self {
            case .completed, .failed, .cancelled:
                return true
            case .queued, .generating:
                return false
            }
        }

        var displayName: String {
            switch self {
            case .queued: return "Queued"
            case .generating: return "Generating"
            case .completed: return "Completed"
            case .failed: return "Failed"
            case .cancelled: return "Cancelled"
            }
        }
    }

    // MARK: - Batch Task

    /// Represents a single image generation task in the batch
    struct BatchTask: Identifiable {
        let id: UUID
        let card: Card
        let prompt: String
        var status: TaskStatus = .queued
        var startedAt: Date?
        var completedAt: Date?

        var elapsedTime: TimeInterval? {
            guard let startTime = startedAt else { return nil }
            if let endTime = completedAt {
                return endTime.timeIntervalSince(startTime)
            }
            return Date().timeIntervalSince(startTime)
        }
    }

    // MARK: - Queue State

    enum QueueState {
        case idle
        case running
        case paused
        case completed
        case cancelled
    }

    // MARK: - Properties

    /// Current state of the queue
    private(set) var state: QueueState = .idle

    /// All tasks in the batch
    private(set) var tasks: [BatchTask] = []

    /// Model context for saving results
    private weak var modelContext: ModelContext?

    /// AI image generator
    private let imageGenerator: AIImageGenerator

    /// Logger
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Cumberland", category: "BatchGenerationQueue")

    /// Maximum concurrent generations (default: 1 to respect rate limits)
    var maxConcurrent: Int = 1

    /// Minimum delay between requests (seconds) for rate limiting
    /// Default: 20 seconds (3 requests/minute) to avoid OpenAI server errors
    var minDelayBetweenRequests: TimeInterval = 20.0

    /// Provider to use for generation
    var provider: String?

    /// Maximum retry attempts for server errors
    var maxRetries: Int = 2

    /// Timestamp of last generation request (for rate limiting)
    private var lastRequestTime: Date?

    /// Active task (for cancellation)
    private var currentTask: Task<Void, Never>?

    // MARK: - Computed Properties

    /// Total number of tasks
    var totalTasks: Int {
        tasks.count
    }

    /// Number of completed tasks
    var completedCount: Int {
        tasks.filter {
            if case .completed = $0.status { return true }
            return false
        }.count
    }

    /// Number of failed tasks
    var failedCount: Int {
        tasks.filter {
            if case .failed = $0.status { return true }
            return false
        }.count
    }

    /// Number of cancelled tasks
    var cancelledCount: Int {
        tasks.filter {
            if case .cancelled = $0.status { return true }
            return false
        }.count
    }

    /// Number of tasks still in progress or queued
    var remainingCount: Int {
        tasks.filter { !$0.status.isTerminal }.count
    }

    /// Overall progress (0.0 to 1.0)
    var progress: Double {
        guard totalTasks > 0 else { return 0.0 }
        return Double(completedCount + failedCount + cancelledCount) / Double(totalTasks)
    }

    /// Whether the queue is actively running
    var isRunning: Bool {
        state == .running
    }

    /// Whether the queue can be started
    var canStart: Bool {
        state == .idle && !tasks.isEmpty
    }

    /// Whether the queue can be paused
    var canPause: Bool {
        state == .running
    }

    /// Whether the queue can be resumed
    var canResume: Bool {
        state == .paused && remainingCount > 0
    }

    /// Whether the queue can be cancelled
    var canCancel: Bool {
        state == .running || state == .paused
    }

    // MARK: - Initialization

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        self.imageGenerator = AIImageGenerator()
    }

    // MARK: - Queue Management

    /// Add cards to the generation queue
    /// - Parameters:
    ///   - cards: Cards to generate images for
    ///   - promptGenerator: Optional closure to generate custom prompts (default: uses card description)
    func addCards(_ cards: [Card], promptGenerator: ((Card) -> String)? = nil) {
        guard state == .idle else {
            logger.warning("Cannot add cards while queue is \(String(describing: self.state))")
            return
        }

        let newTasks = cards.map { card in
            let prompt: String
            if let generator = promptGenerator {
                prompt = generator(card)
            } else {
                // Default: use card's detailed text as prompt
                prompt = generatePrompt(for: card)
            }

            return BatchTask(
                id: card.id,
                card: card,
                prompt: prompt,
                status: .queued
            )
        }

        tasks.append(contentsOf: newTasks)
        logger.info("Added \(newTasks.count) cards to batch queue (total: \(self.tasks.count))")
    }

    /// Generate a prompt from a card's content
    private func generatePrompt(for card: Card) -> String {
        var prompt = ""

        // Check if card name might trigger content filters (common weapon/violence terms)
        let sensitivePrefixes = ["weapon", "gun", "rifle", "pistol", "sword", "blade", "knife", "axe", "bomb", "explosive"]
        let nameWords = card.name.lowercased().split(separator: " ").map(String.init)
        let hasSensitiveTerm = nameWords.contains { word in
            sensitivePrefixes.contains(where: { word.contains($0) })
        }

        // For artifacts with potentially sensitive names, prioritize description over name
        if card.kind == .artifacts && hasSensitiveTerm && !card.detailedText.isEmpty {
            // Use description first to establish context
            let maxLength = 400
            let trimmedText = card.detailedText.prefix(maxLength)
            prompt = String(trimmedText)

            // Optionally add sanitized name reference at end
            if !card.subtitle.isEmpty {
                prompt += ". Also known as \(card.subtitle)"
            }
        } else {
            // Normal prompt generation: name first

            // Use card name as primary subject
            if !card.name.isEmpty {
                prompt += card.name
            }

            // Add subtitle for context
            if !card.subtitle.isEmpty {
                prompt += prompt.isEmpty ? card.subtitle : ", \(card.subtitle)"
            }

            // Add details if available and not too long
            if !card.detailedText.isEmpty {
                let maxLength = 500 // Reasonable prompt length
                let trimmedText = card.detailedText.prefix(maxLength)
                prompt += prompt.isEmpty ? String(trimmedText) : ". \(trimmedText)"
            }
        }

        // Fallback
        if prompt.isEmpty {
            // For artifacts, use generic description to avoid content filters
            if card.kind == .artifacts {
                prompt = "A detailed illustration of a \(card.kind.title.dropLastIfPluralized())"
            } else {
                prompt = "A \(card.kind.title.dropLastIfPluralized()) named \(card.name)"
            }
        }

        return prompt
    }

    /// Start processing the queue
    func start() async {
        guard canStart else {
            logger.warning("Cannot start queue: state=\(String(describing: self.state)), tasks=\(self.tasks.count)")
            return
        }

        state = .running
        logger.info("Starting batch generation queue with \(self.tasks.count) tasks")

        currentTask = Task { @MainActor in
            await processQueue()
        }

        await currentTask?.value
    }

    /// Pause the queue (current generation will complete)
    func pause() {
        guard canPause else { return }
        state = .paused
        logger.info("Pausing batch generation queue")
    }

    /// Resume a paused queue
    func resume() async {
        guard canResume else { return }
        state = .running
        logger.info("Resuming batch generation queue")

        currentTask = Task { @MainActor in
            await processQueue()
        }

        await currentTask?.value
    }

    /// Cancel the queue (stops all pending tasks)
    func cancel() {
        guard canCancel else { return }

        logger.info("Cancelling batch generation queue")

        // Cancel current task
        currentTask?.cancel()
        currentTask = nil

        // Mark all non-terminal tasks as cancelled
        for i in 0..<tasks.count {
            if !tasks[i].status.isTerminal {
                tasks[i].status = .cancelled
            }
        }

        state = .cancelled
    }

    /// Clear all tasks and reset queue
    func reset() {
        cancel()
        tasks.removeAll()
        state = .idle
        lastRequestTime = nil
        logger.info("Reset batch generation queue")
    }

    // MARK: - Queue Processing

    @MainActor
    private func processQueue() async {
        logger.debug("Processing queue (remaining: \(self.remainingCount))")

        // Process tasks sequentially (respecting maxConcurrent in future enhancement)
        for i in 0..<tasks.count {
            // Check if we should stop
            guard state == .running else {
                logger.debug("Queue stopped (state: \(String(describing: self.state)))")
                break
            }

            // Skip already-processed tasks
            if tasks[i].status.isTerminal {
                continue
            }

            // Process this task
            await processTask(at: i)
        }

        // Queue completed
        if state == .running {
            state = .completed
            logger.info("Batch generation completed: \(self.completedCount)/\(self.totalTasks) succeeded, \(self.failedCount) failed")
        }
    }

    @MainActor
    private func processTask(at index: Int) async {
        guard index < tasks.count else { return }

        var task = tasks[index]
        let card = task.card

        logger.debug("Processing task \(index + 1)/\(self.totalTasks): '\(card.name)'")

        // Update status to generating
        task.status = .generating
        task.startedAt = Date()
        tasks[index] = task

        // Rate limiting: wait if needed
        if let lastRequest = lastRequestTime {
            let elapsed = Date().timeIntervalSince(lastRequest)
            if elapsed < minDelayBetweenRequests {
                let waitTime = minDelayBetweenRequests - elapsed
                logger.debug("Rate limiting: waiting \(waitTime)s before next request")
                try? await Task.sleep(for: .seconds(waitTime))
            }
        }

        lastRequestTime = Date()

        // Generate image with retry logic for server errors
        logger.info("🎨 Generating image for '\(card.name)' with provider: '\(self.provider ?? "default")'")
        logger.info("📝 Prompt: '\(task.prompt.prefix(100))...'")

        var lastError: Error?
        var retryCount = 0

        while retryCount <= self.maxRetries {
            do {
                let (_, data) = try await self.imageGenerator.generateImage(
                    prompt: task.prompt,
                    provider: self.provider
                )

                // Save to card
                if let context = self.modelContext {
                    // Set image data and metadata
                    card.originalImageData = data
                    card.imageGeneratedByAI = true
                    card.imageAIProvider = self.provider ?? AISettings.shared.imageGenerationProvider
                    card.imageAIPrompt = task.prompt
                    card.imageAIGeneratedAt = Date()

                    // Generate thumbnail
                    if let thumbnail = generateThumbnail(from: data) {
                        card.thumbnailData = thumbnail
                    }

                    // Save
                    try context.save()

                    logger.info("✅ Generated image for '\(card.name)'\(retryCount > 0 ? " (after \(retryCount) retries)" : "")")
                }

                // Update status to completed
                task.status = .completed(imageData: data)
                task.completedAt = Date()
                tasks[index] = task
                return // Success!

            } catch {
                lastError = error

                // Check for non-retryable errors (permanent failures)
                let errorDesc = error.localizedDescription.lowercased()
                let isContentFilter = errorDesc.contains("content filter") ||
                                     errorDesc.contains("safety system") ||
                                     errorDesc.contains("safety filter")
                let isAuthError = errorDesc.contains("api key") ||
                                 errorDesc.contains("authentication") ||
                                 errorDesc.contains("unauthorized")
                let isInvalidRequest = errorDesc.contains("invalid request") ||
                                      errorDesc.contains("invalid input")

                // Content filters, auth errors, and invalid requests are permanent - don't retry
                if isContentFilter || isAuthError || isInvalidRequest {
                    logger.error("❌ Non-retryable error for '\(card.name)': \(error.localizedDescription)")
                    break
                }

                // Check if this is a retryable server/network error
                let isServerError = errorDesc.contains("server had an error") ||
                                   errorDesc.contains("server error") ||
                                   errorDesc.contains("503") ||
                                   errorDesc.contains("500") ||
                                   errorDesc.contains("overloaded") ||
                                   errorDesc.contains("timed out") ||
                                   errorDesc.contains("timeout") ||
                                   errorDesc.contains("network error") ||
                                   errorDesc.contains("connection") ||
                                   errorDesc.contains("unreachable")

                if isServerError && retryCount < self.maxRetries {
                    let backoffDelay = Double(retryCount + 1) * 5.0 // 5s, 10s exponential backoff
                    let errorType = errorDesc.contains("timed out") || errorDesc.contains("timeout") ? "Timeout" : "Server error"
                    logger.warning("⚠️ \(errorType) for '\(card.name)', retrying in \(backoffDelay)s (attempt \(retryCount + 1)/\(self.maxRetries))")
                    try? await Task.sleep(for: .seconds(backoffDelay))
                    retryCount += 1
                    continue
                }

                // Not retryable or out of retries
                logger.debug("Not retrying '\(card.name)' - either not a server error or max retries reached")
                break
            }
        }

        // All retries exhausted or non-retryable error
        if let error = lastError {
            var errorMsg = "\(error.localizedDescription) [Provider: \(self.provider ?? "default")]"

            // Add retry info if retries were attempted
            if retryCount > 0 {
                errorMsg += " (failed after \(retryCount) \(retryCount == 1 ? "retry" : "retries"))"
            }

            // Add helpful hints based on error type
            let errorDesc = error.localizedDescription.lowercased()
            if errorDesc.contains("content filter") || errorDesc.contains("safety system") {
                errorMsg += "\n\nTip: Try simplifying the prompt or removing potentially sensitive terms (e.g., 'weapon', 'rifle', 'gun'). Content filter blocks are permanent and cannot be retried."
            } else if errorDesc.contains("timed out") || errorDesc.contains("timeout") {
                errorMsg += "\n\nNote: Image generation can take 30-60 seconds. This timeout occurred after automatic retries. Try again with a smaller batch or check your network connection."
            }

            logger.error("❌ Failed to generate image for '\(card.name)': \(errorMsg)")
            logger.error("❌ Error details: \(String(describing: error))")

            // Update status to failed
            task.status = .failed(error: errorMsg)
            task.completedAt = Date()
            tasks[index] = task
        }
    }

    // MARK: - Thumbnail Generation

    private func generateThumbnail(from imageData: Data) -> Data? {
        #if os(macOS)
        guard let nsImage = NSImage(data: imageData) else { return nil }
        let targetSize = CGSize(width: 200, height: 200)

        let ratio = min(targetSize.width / nsImage.size.width, targetSize.height / nsImage.size.height)
        let newSize = CGSize(width: nsImage.size.width * ratio, height: nsImage.size.height * ratio)

        let thumbnail = NSImage(size: newSize)
        thumbnail.lockFocus()
        nsImage.draw(in: CGRect(origin: .zero, size: newSize))
        thumbnail.unlockFocus()

        // Convert to PNG data
        guard let tiffData = thumbnail.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmapRep.representation(using: .png, properties: [:])

        #else
        guard let uiImage = UIImage(data: imageData) else { return nil }
        let targetSize = CGSize(width: 200, height: 200)

        let ratio = min(targetSize.width / uiImage.size.width, targetSize.height / uiImage.size.height)
        let newSize = CGSize(width: uiImage.size.width * ratio, height: uiImage.size.height * ratio)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        uiImage.draw(in: CGRect(origin: .zero, size: newSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return thumbnail?.pngData()
        #endif
    }

    // MARK: - Retry Failed Tasks

    /// Retry all failed tasks
    func retryFailed() async {
        guard state == .completed || state == .cancelled else {
            logger.warning("Cannot retry while queue is running")
            return
        }

        // Reset failed tasks to queued
        for i in 0..<tasks.count {
            if case .failed = tasks[i].status {
                tasks[i].status = .queued
                tasks[i].startedAt = nil
                tasks[i].completedAt = nil
            }
        }

        let failedCount = tasks.filter {
            if case .queued = $0.status { return true }
            return false
        }.count

        guard failedCount > 0 else { return }

        logger.info("Retrying \(failedCount) failed tasks")

        // Restart queue
        state = .running
        currentTask = Task { @MainActor in
            await processQueue()
        }

        await currentTask?.value
    }
}

// MARK: - Result Summary

extension BatchGenerationQueue {
    /// Get a summary of the batch results
    struct BatchResult {
        let totalTasks: Int
        let completed: Int
        let failed: Int
        let cancelled: Int
        let averageTime: TimeInterval?

        var successRate: Double {
            guard totalTasks > 0 else { return 0.0 }
            return Double(completed) / Double(totalTasks)
        }

        var displaySummary: String {
            "\(completed) of \(totalTasks) images generated successfully"
        }
    }

    var result: BatchResult {
        let completedTasks = tasks.filter {
            if case .completed = $0.status { return true }
            return false
        }

        let avgTime: TimeInterval? = {
            let times = completedTasks.compactMap { $0.elapsedTime }
            guard !times.isEmpty else { return nil }
            return times.reduce(0, +) / Double(times.count)
        }()

        return BatchResult(
            totalTasks: totalTasks,
            completed: completedCount,
            failed: failedCount,
            cancelled: cancelledCount,
            averageTime: avgTime
        )
    }
}
