//
//  ContentView.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/10/25.
//
//  Root view dispatcher. Routes to VisionOSContentView on visionOS (with
//  immersive-space toggle support) or directly to MainAppView on macOS/iOS.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        #if os(visionOS)
        VisionOSContentView()
        #else
        MainAppView()
        #endif
    }
}

#if os(visionOS)
import RealityKit
import RealityKitContent

struct VisionOSContentView: View {
    @State private var showMainApp = false
    
    var body: some View {
        if showMainApp {
            MainAppView()
        } else {
            VStack(spacing: 30) {
                Model3D(named: "Scene", bundle: realityKitContentBundle)
                    .frame(width: 400, height: 300)
                
                VStack(spacing: 16) {
                    Text("Cumberland")
                        .font(.largeTitle).bold()
                    
                    Text("Your Creative Writing Companion")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showMainApp = true
                        }
                    } label: {
                        Label("Get Started", systemImage: "arrow.right.circle.fill")
                            .font(.title2)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                }
                
//                ToggleImmersiveSpaceButton()
            }
            .padding()
            .glassEffect(.regular, in: .rect(cornerRadius: 24))
        }
    }
}
#endif

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Card.self, configurations: config)
    
    return ContentView()
        .modelContainer(container)
}
