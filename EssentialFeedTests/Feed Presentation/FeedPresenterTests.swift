//
//  FeedPresenterTests.swift
//  EssentialFeedTests
//
//  Created by Joanda Febrian on 17/03/23.
//

import XCTest

final class FeedPresenter {
    init(view: Any) {

    }
}

final class FeedPresenterTests: XCTestCase {
    
    func test_init_doesNotSendMessagesToView() {
        let view = ViewSpy()

        _ = FeedPresenter(view: view)

        XCTAssertTrue(view.messages.isEmpty, "Expected no view messages")
    }

    // MARK: - Helpers

    private class ViewSpy {
        let messages = [Any]()
    }
}
