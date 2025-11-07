import SwiftUI
import Combine
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

// Example implementation showing how to use Solution 1: Protocol-Based Drop Zone Integration

// MARK: - Example Drop-Capable Target

class CardDropTarget: ObservableObject, DropCapableTarget {
    let objectWillChange = ObservableObjectPublisher()
    
    let gestureID = UUID()
    @Published var worldBounds: CGRect
    @Published var isHighlighted = false
    
    let card: Card
    
    // Drop configuration
    let acceptedDropTypes: [UTType] = [.cardReference, .text, .image, .fileURL]
    
    init(card: Card, worldBounds: CGRect) {
        self.card = card
        self.worldBounds = worldBounds
    }
    
    // MARK: - GestureTarget Conformance
    
    func canHandleGesture(_ gesture: GestureType) -> Bool {
        switch gesture {
        case .tap, .drag, .rightClick:
            return true
        default:
            return false
        }
    }
    
    func handleGesture(_ gesture: GestureEvent) {
        switch gesture {
        case .tap(let location, let coordinateSpace):
            handleTap(at: location, coordinateSpace: coordinateSpace)
        case .dragBegan(let startLocation, let coordinateSpace):
            handleDragBegan(at: startLocation, coordinateSpace: coordinateSpace)
        case .dragChanged(let location, let translation, let coordinateSpace):
            handleDragChanged(at: location, translation: translation, coordinateSpace: coordinateSpace)
        case .dragEnded(let location, let translation, let velocity, let coordinateSpace):
            handleDragEnded(at: location, translation: translation, velocity: velocity, coordinateSpace: coordinateSpace)
        case .rightClick(let location, let coordinateSpace):
            showContextMenu(at: location, coordinateSpace: coordinateSpace)
        default:
            break
        }
    }
    
    // MARK: - DropCapableTarget Conformance
    
    func dragEntered(with session: DropSession, at location: CGPoint, coordinateSpace: CoordinateSpaceInfo) {
        withAnimation(.easeInOut(duration: 0.2)) {
            isHighlighted = true
        }
    }
    
    func dragUpdated(with session: DropSession, at location: CGPoint, coordinateSpace: CoordinateSpaceInfo) -> DropProposal {
        // Determine the appropriate drop operation based on content
        if session.hasItemsConforming(to: [.cardReference]) {
            return .move // Moving cards between containers
        } else if session.hasItemsConforming(to: [.text]) {
            return .copy // Adding text content to card
        } else if session.hasItemsConforming(to: [.image]) {
            return .copy // Adding images to card
        } else {
            return .forbidden
        }
    }
    
    func dragExited() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isHighlighted = false
        }
    }
    
    func performDrop(with session: DropSession, at location: CGPoint, coordinateSpace: CoordinateSpaceInfo) -> Bool {
        let worldLocation = coordinateSpace.toWorldSpace(location)
        
        for item in session.items {
            let provider = item.itemProvider
            
            // Handle card reference drops
            if provider.hasItemConformingToTypeIdentifier(UTType.cardReference.identifier) {
                handleCardReferenceDrop(provider: provider, at: worldLocation)
                return true
            }
            
            // Handle text drops
            if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                handleTextDrop(provider: provider, at: worldLocation)
                return true
            }
            
            // Handle image drops
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                handleImageDrop(provider: provider, at: worldLocation)
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Private Drop Handlers
    
    private func handleTap(at location: CGPoint, coordinateSpace: CoordinateSpaceInfo) {
        // Handle card selection/interaction
        print("Card tapped: \(card.name)")
    }
    
    private func showContextMenu(at location: CGPoint, coordinateSpace: CoordinateSpaceInfo) {
        // Show context menu for card
        print("Show context menu for card: \(card.name)")
    }
    
    private func handleDragBegan(at location: CGPoint, coordinateSpace: CoordinateSpaceInfo) {
        // Handle the start of card dragging
        print("Drag began for card: \(card.name)")
        // You could set a dragging state here if needed
    }
    
    private func handleDragChanged(at location: CGPoint, translation: CGSize, coordinateSpace: CoordinateSpaceInfo) {
        // Handle ongoing drag movement
        // You could update the card's position here or provide visual feedback
        print("Dragging card: \(card.name) at translation: \(translation)")
    }
    
    private func handleDragEnded(at location: CGPoint, translation: CGSize, velocity: CGSize, coordinateSpace: CoordinateSpaceInfo) {
        // Handle the end of card dragging
        print("Drag ended for card: \(card.name) with final translation: \(translation)")
        // You could update the card's final position or trigger drop behavior here
    }
    
    private func handleCardReferenceDrop(provider: NSItemProvider, at location: CGPoint) {
        provider.loadItem(forTypeIdentifier: UTType.cardReference.identifier, options: nil) { item, error in
            guard let data = item as? Data,
                  let cardTransfer = try? JSONDecoder().decode(CardTransferData.self, from: data) else {
                return
            }
            
            Task { @MainActor in
                // Handle moving or linking cards
                print("Dropped card: \(cardTransfer.name) onto \(self.card.name)")
            }
        }
    }
    
    private func handleTextDrop(provider: NSItemProvider, at location: CGPoint) {
        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, error in
            guard let text = item as? String else { return }
            
            Task { @MainActor in
                // Add text to card details or create new text element
                if self.card.detailedText.isEmpty {
                    self.card.detailedText = text
                } else {
                    self.card.detailedText += "\n\n\(text)"
                }
                print("Added text to card: \(self.card.name)")
            }
        }
    }
    
    private func handleImageDrop(provider: NSItemProvider, at location: CGPoint) {
        #if canImport(UIKit)
        // Handle UIImage for iOS/iPadOS
        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { image, error in
                guard let image = image as? UIImage else { return }
                
                Task { @MainActor in
                    // Set card image using the proper method
                    if let imageData = image.pngData() {
                        try? self.card.setOriginalImageData(imageData, preferredFileExtension: "png")
                    }
                    print("Added UIImage to card: \(self.card.name)")
                }
            }
            return
        }
        #endif
        
        #if canImport(AppKit)
        // Handle NSImage for macOS
        if provider.canLoadObject(ofClass: NSImage.self) {
            provider.loadObject(ofClass: NSImage.self) { image, error in
                guard let image = image as? NSImage else { return }
                
                Task { @MainActor in
                    // Set card image using the proper method
                    if let imageData = image.pngData() {
                        try? self.card.setOriginalImageData(imageData, preferredFileExtension: "png")
                    }
                    print("Added NSImage to card: \(self.card.name)")
                }
            }
            return
        }
        #endif
        
        // Fallback: try to load as Data
        provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, error in
            guard let imageData = item as? Data else { return }
            
            Task { @MainActor in
                try? self.card.setOriginalImageData(imageData, preferredFileExtension: "png")
                print("Added image data to card: \(self.card.name)")
            }
        }
    }
}

// MARK: - Example SwiftUI View

struct CardCanvasView: View {
    @StateObject private var gestureHandler: MultiGestureHandler
    @State private var coordinateInfo: CoordinateSpaceInfo
    @State private var cardTargets: [CardDropTarget] = []
    
    let cards: [Card]
    
    init(cards: [Card]) {
        self.cards = cards
        let spaceName = "cardCanvas"
        self._gestureHandler = StateObject(wrappedValue: MultiGestureHandler(coordinateSpace: spaceName))
        self._coordinateInfo = State(initialValue: CoordinateSpaceInfo(
            spaceName: spaceName,
            transform: .identity,
            zoomScale: 1.0,
            panOffset: .zero
        ))
    }
    
    var body: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(Color.gray.opacity(0.1))
            
            // Cards
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                CardDropTargetView(
                    card: card,
                    target: cardTargets.first { $0.card.id == card.id }
                )
                .position(x: card.position.x, y: card.position.y)
            }
        }
        .coordinateSpace(name: "cardCanvas")
        .multiGestureHandler(gestureHandler, coordinateInfo: coordinateInfo)
        .onAppear {
            setupCardTargets()
        }
        .onChange(of: cards) {
            setupCardTargets()
        }
    }
    
    private func setupCardTargets() {
        // Clean up existing targets
        cardTargets.forEach { gestureHandler.unregisterTarget($0) }
        cardTargets.removeAll()
        
        // Create new targets for each card
        for card in cards {
            let cardBounds = CGRect(
                x: card.position.x - 50, // Half card width
                y: card.position.y - 70, // Half card height
                width: 100,
                height: 140
            )
            
            let target = CardDropTarget(card: card, worldBounds: cardBounds)
            cardTargets.append(target)
            gestureHandler.registerTarget(target)
        }
    }
}

// MARK: - Individual Card Drop Target View

struct CardDropTargetView: View {
    let card: Card
    let target: CardDropTarget?
    
    var body: some View {
        VStack {
            // Card image
            #if canImport(UIKit)
            if let thumbnailData = card.thumbnailData,
               let image = UIImage(data: thumbnailData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 60)
                    .clipped()
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 60)
            }
            #elseif canImport(AppKit)
            if let thumbnailData = card.thumbnailData,
               let image = NSImage(data: thumbnailData) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 60)
                    .clipped()
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 60)
            }
            #endif
            
            // Card title
            Text(card.name)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .stroke(
                    target?.isHighlighted == true ? Color.accentColor : Color.clear,
                    lineWidth: 2
                )
        }
        .scaleEffect(target?.isHighlighted == true ? 1.05 : 1.0)
        .shadow(radius: target?.isHighlighted == true ? 8 : 2)
    }
}

// MARK: - Extension for Card Position

extension Card {
    var position: CGPoint {
        // This would be stored in your Card model
        // For example purposes, using a computed property
        CGPoint(x: CGFloat(name.hash % 400) + 100, y: CGFloat((name.hash / 400) % 300) + 100)
    }
}

// MARK: - Cross-Platform Image Extensions

#if canImport(AppKit)
extension NSImage {
    func pngData() -> Data? {
        guard let tiffRepresentation = tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else {
            return nil
        }
        return bitmapImage.representation(using: .png, properties: [:])
    }
}
#endif

// MARK: - Cross-Platform Image Helper
struct ImageDataHelper {
    static func pngData(from imageData: Data) -> Data? {
        #if canImport(UIKit)
        guard let image = UIImage(data: imageData) else { return nil }
        return image.pngData()
        #elseif canImport(AppKit)
        guard let image = NSImage(data: imageData) else { return nil }
        return image.pngData()
        #else
        return imageData // Fallback: assume it's already PNG data
        #endif
    }
}

// MARK: - Preview

struct CardCanvasView_Previews: PreviewProvider {
    static var previews: some View {
        CardCanvasView(cards: [
            // Sample cards would go here
        ])
    }
}
