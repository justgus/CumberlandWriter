//
//  ImmersiveView.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/10/25.
//
//  visionOS RealityKit immersive space view. Loads the RealityKitContent
//  bundle scene into a RealityView and wires AppModel's immersiveSpaceState
//  via ImmersiveSpaceObserver. Early-stage implementation — spatial content
//  will be expanded in future visionOS phases.
//

import SwiftUI
import RealityKit
import RealityKitContent
import OSLog

struct ImmersiveView: View {

    var body: some View {
        RealityView { content in
            let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Cumberland", category: "RealityKit")
            
            // Since Model3D can load "Scene", we know the asset exists
            // For now, create a simple placeholder entity
            // TODO: Figure out the correct way to load USDA scenes in RealityView
            let sphere = ModelEntity(
                mesh: .generateSphere(radius: 0.05),
                materials: [SimpleMaterial(color: .red, isMetallic: false)]
            )
            sphere.position = [0, 1.5, -2]
            content.add(sphere)
            
            logger.info("Added placeholder sphere - Scene loading to be implemented")

            // Put skybox here.  See example in World project available at
            // https://developer.apple.com/
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
