//
//  ImmersiveView.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/10/25.
//

import SwiftUI
import RealityKit
import RealityKitContent
import OSLog

struct ImmersiveView: View {

    var body: some View {
        RealityView { content in
            let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Cumberland", category: "RealityKit")
            
            // Create content programmatically to avoid asset loading issues
            let rootEntity = Entity()
            
            // Try to load the Scene asset first
            do {
                let sceneEntity = try await Entity(named: "Scene", in: realityKitContentBundle)
                logger.info("Successfully loaded Scene entity")
                rootEntity.addChild(sceneEntity)
            } catch {
                logger.error("Failed to load Scene entity: \(error.localizedDescription)")
                // Create fallback content
                let sphereEntity = Entity()
                sphereEntity.components[ModelComponent.self] = ModelComponent(
                    mesh: .generateSphere(radius: 0.05),
                    materials: [SimpleMaterial(color: .red, isMetallic: false)]
                )
                sphereEntity.position = [0, 1.5, -2]
                rootEntity.addChild(sphereEntity)
            }
            
            content.add(rootEntity)

            // Put skybox here.  See example in World project available at
            // https://developer.apple.com/
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
