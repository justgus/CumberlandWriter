import Foundation
import NaturalLanguage

/// Preprocesses long text for AI analysis by extracting keywords and condensing content
/// Phase 5 Enhancement - Handles chapter-length prose efficiently
///
/// Strategy:
/// 1. Extract proper nouns and key entities using NaturalLanguage framework
/// 2. Identify sentences containing those entities
/// 3. Create condensed version with context preserved
/// 4. Reduce 10,000 word chapter to ~1,000 word summary for analysis
class TextPreprocessor {

    // MARK: - Configuration

    struct Config {
        /// Maximum words to send to AI (condensed version)
        var maxWords: Int = 1000

        /// Context words to include before/after entity mentions
        var contextWordsPerSide: Int = 15

        /// Minimum word count before preprocessing kicks in
        var preprocessThreshold: Int = 500

        /// Maximum sentences to include per entity
        var maxSentencesPerEntity: Int = 3
    }

    private let config: Config

    // MARK: - Initialization

    init(config: Config = Config()) {
        self.config = config
    }

    // MARK: - Public API

    /// Preprocess text for analysis
    /// - Parameter text: Original text (may be very long)
    /// - Returns: Preprocessed result with condensed text and metadata
    func preprocess(_ text: String) -> PreprocessResult {
        let wordCount = text.split(separator: " ").count

        // Skip preprocessing for short text
        guard wordCount > config.preprocessThreshold else {
            return PreprocessResult(
                originalWordCount: wordCount,
                condensedText: text,
                condensedWordCount: wordCount,
                wasPreprocessed: false,
                extractedEntities: []
            )
        }

        #if DEBUG
        print("📝 [TextPreprocessor] Preprocessing long text (\(wordCount) words)")
        #endif

        let startTime = Date()

        // Extract proper nouns and key entities
        let entities = extractProperNouns(from: text)

        // Find sentences containing those entities
        let keySentences = extractKeySentences(from: text, containing: entities)

        // Build condensed text
        let condensedText = buildCondensedText(from: keySentences)
        let condensedWordCount = condensedText.split(separator: " ").count

        let processingTime = Date().timeIntervalSince(startTime)

        #if DEBUG
        print("✅ [TextPreprocessor] Condensed \(wordCount) → \(condensedWordCount) words (\(String(format: "%.1f", Double(condensedWordCount) / Double(wordCount) * 100))%) in \(String(format: "%.2f", processingTime))s")
        print("   Extracted \(entities.count) key entities")
        print("   Found \(keySentences.count) relevant sentences")
        #endif

        return PreprocessResult(
            originalWordCount: wordCount,
            condensedText: condensedText,
            condensedWordCount: condensedWordCount,
            wasPreprocessed: true,
            extractedEntities: entities,
            keySentenceCount: keySentences.count,
            processingTime: processingTime
        )
    }

    // MARK: - Proper Noun Extraction

    /// Extract proper nouns (character names, place names, organization names) using NaturalLanguage
    private func extractProperNouns(from text: String) -> [String] {
        var properNouns = Set<String>()

        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text

        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        let tags: [NLTag] = [.personalName, .placeName, .organizationName]

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            guard let tag = tag, tags.contains(tag) else { return true }
            let name = String(text[tokenRange])
            properNouns.insert(name)
            return true
        }

        return Array(properNouns).sorted()
    }

    // MARK: - Key Sentence Extraction

    /// Extract sentences that contain proper nouns or key entities
    private func extractKeySentences(from text: String, containing entities: [String]) -> [String] {
        guard !entities.isEmpty else {
            // No entities found - fall back to first N sentences
            return extractFirstSentences(from: text, limit: 20)
        }

        var keySentences = Set<String>()
        var entityMentionCounts: [String: Int] = [:]

        // Split text into sentences
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text

        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { sentenceRange, _ in
            let sentence = String(text[sentenceRange]).trimmingCharacters(in: .whitespacesAndNewlines)

            // Check if sentence contains any entities
            for entity in entities {
                if sentence.localizedCaseInsensitiveContains(entity) {
                    // Limit mentions per entity to avoid redundancy
                    let count = entityMentionCounts[entity, default: 0]
                    if count < config.maxSentencesPerEntity {
                        keySentences.insert(sentence)
                        entityMentionCounts[entity] = count + 1
                    }
                    break // Don't count same sentence multiple times
                }
            }

            return true
        }

        // If we found very few sentences, add some context
        if keySentences.count < 10 {
            let firstSentences = extractFirstSentences(from: text, limit: 10 - keySentences.count)
            keySentences.formUnion(firstSentences)
        }

        return Array(keySentences)
    }

    /// Extract first N sentences from text
    private func extractFirstSentences(from text: String, limit: Int) -> [String] {
        var sentences: [String] = []

        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text

        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { sentenceRange, _ in
            let sentence = String(text[sentenceRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            sentences.append(sentence)
            return sentences.count < limit
        }

        return sentences
    }

    // MARK: - Condensed Text Building

    /// Build condensed text from key sentences
    private func buildCondensedText(from sentences: [String]) -> String {
        // Join sentences with proper spacing
        var condensedText = sentences.joined(separator: " ")

        // Trim to max words if still too long
        let words = condensedText.split(separator: " ")
        if words.count > config.maxWords {
            condensedText = words.prefix(config.maxWords).joined(separator: " ")
            condensedText += "..." // Indicate truncation
        }

        return condensedText
    }

    // MARK: - Chunking (Alternative Strategy)

    /// Chunk text into smaller pieces for separate analysis (alternative to condensing)
    /// Returns array of text chunks, each under maxWords
    func chunkText(_ text: String, maxWordsPerChunk: Int = 500) -> [String] {
        let words = text.split(separator: " ")
        var chunks: [String] = []

        var currentChunk: [Substring] = []
        var currentWordCount = 0

        for word in words {
            currentChunk.append(word)
            currentWordCount += 1

            if currentWordCount >= maxWordsPerChunk {
                chunks.append(currentChunk.joined(separator: " "))
                currentChunk = []
                currentWordCount = 0
            }
        }

        // Add remaining words
        if !currentChunk.isEmpty {
            chunks.append(currentChunk.joined(separator: " "))
        }

        return chunks
    }
}

// MARK: - Result Type

/// Result of text preprocessing
struct PreprocessResult {
    /// Original text word count
    let originalWordCount: Int

    /// Condensed text (ready for AI analysis)
    let condensedText: String

    /// Condensed text word count
    let condensedWordCount: Int

    /// Whether preprocessing was applied (false if text was short enough)
    let wasPreprocessed: Bool

    /// Entities extracted during preprocessing
    let extractedEntities: [String]

    /// Number of key sentences extracted (optional)
    let keySentenceCount: Int?

    /// Time taken to preprocess (optional)
    let processingTime: TimeInterval?

    init(
        originalWordCount: Int,
        condensedText: String,
        condensedWordCount: Int,
        wasPreprocessed: Bool,
        extractedEntities: [String],
        keySentenceCount: Int? = nil,
        processingTime: TimeInterval? = nil
    ) {
        self.originalWordCount = originalWordCount
        self.condensedText = condensedText
        self.condensedWordCount = condensedWordCount
        self.wasPreprocessed = wasPreprocessed
        self.extractedEntities = extractedEntities
        self.keySentenceCount = keySentenceCount
        self.processingTime = processingTime
    }

    /// Compression ratio (0.0 to 1.0)
    var compressionRatio: Double {
        guard originalWordCount > 0 else { return 1.0 }
        return Double(condensedWordCount) / Double(originalWordCount)
    }

    /// User-facing description
    var description: String {
        if wasPreprocessed {
            return "Analyzed \(condensedWordCount) key words from \(originalWordCount) word text (\(Int(compressionRatio * 100))%)"
        } else {
            return "Analyzed full text (\(originalWordCount) words)"
        }
    }
}

// MARK: - Configuration Presets

extension TextPreprocessor.Config {
    /// Fast preprocessing - aggressive condensing
    static var fast: TextPreprocessor.Config {
        TextPreprocessor.Config(
            maxWords: 500,
            contextWordsPerSide: 10,
            preprocessThreshold: 300,
            maxSentencesPerEntity: 2
        )
    }

    /// Balanced preprocessing - default
    static var balanced: TextPreprocessor.Config {
        TextPreprocessor.Config()
    }

    /// Thorough preprocessing - preserve more context
    static var thorough: TextPreprocessor.Config {
        TextPreprocessor.Config(
            maxWords: 1500,
            contextWordsPerSide: 20,
            preprocessThreshold: 700,
            maxSentencesPerEntity: 5
        )
    }
}
