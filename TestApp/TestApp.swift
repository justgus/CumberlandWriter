//
//  TestApp.swift
//  Cumberland
//
//  Created by Assistant on 10/31/25.
//
//  Standalone SwiftUI @main entry point for the MultiGestureTestView harness.
//  Used to interactively verify the MultiGestureHandler and gesture routing
//  system in isolation, without launching the full Cumberland app.
//

import SwiftUI

@main
struct TestApp: App {
    var body: some Scene {
        WindowGroup {
            MultiGestureTestView()
        }
    }
}