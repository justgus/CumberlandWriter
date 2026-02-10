//
//  CumberlandVisionOSUITestsLaunchTests.swift
//  CumberlandVisionOSUITests
//
//  Created by Mike Stoddard on 1/20/26.
//
//  XCTest launch test for the visionOS Cumberland target. Captures a
//  screenshot at application launch across all UI configurations as a
//  visual baseline.
//

import XCTest

final class CumberlandVisionOSUITestsLaunchTests: XCTestCase {

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
