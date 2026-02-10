//
//  CumberlandUITestsLaunchTests.swift
//  CumberlandUITests
//
//  Created by Mike Stoddard on 10/1/25.
//
//  XCTest launch test for the macOS Cumberland target. Captures a screenshot
//  at application launch to serve as a baseline for visual regression and
//  runs across all target application UI configurations.
//

import XCTest

final class CumberlandUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
