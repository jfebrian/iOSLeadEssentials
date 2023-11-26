//
//  FeedImagePresenterTests.swift
//  EssentialFeedTests
//
//  Created by Joanda Febrian on 17/03/23.
//

import XCTest
import EssentialFeed

final class FeedImagePresenterTests: XCTestCase {
    func test_map_createsViewModel() {
        let image = uniqueImage()

        let viewModel = FeedImagePresenter.map(image)

        XCTAssertEqual(viewModel.description, image.description)
        XCTAssertEqual(viewModel.location, image.location)
    }
}
