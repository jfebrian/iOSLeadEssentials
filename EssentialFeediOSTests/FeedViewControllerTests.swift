//
//  FeedViewControllerTests.swift
//  EssentialFeediOSTests
//
//  Created by Joanda Febrian on 22/01/23.
//

import XCTest

final class FeedViewController {
    init(loader: FeedViewControllerTests.LoaderSpy) {
        
    }
}

final class FeedViewControllerTests: XCTestCase {
    func test_init_doesNotLoadFeed() {
        let loader = LoaderSpy()
        _ = FeedViewController(loader: loader)
        
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
    // MARK: - Helpers
    
    class LoaderSpy {
        private(set) var loadCallCount = 0
    }
}
