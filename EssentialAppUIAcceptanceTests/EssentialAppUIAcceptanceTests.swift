// Created by Joanda Febrian. All rights reserved.

import XCTest

final class EssentialAppUIAcceptanceTests: XCTestCase {
    func test_onLaunch_displaysRemoteFeedWhenCustomerHasConnectivity() {
        let app = XCUIApplication()

        app.launch()

        XCTAssertEqual(app.cells.count, 22)
        XCTAssertGreaterThanOrEqual(app.images.count, 1)
    }
}
