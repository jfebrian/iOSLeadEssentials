//
//  FeedLocalizationTests.swift
//  EssentialFeediTests
//
//  Created by Joanda Febrian on 22/02/23.
//

import XCTest
import EssentialFeed

@testable import EssentialFeediOS

final class FeedLocalizationTests: XCTestCase {

    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        assertLocalizedKeyAndValuesExist(in: Bundle(for: FeedPresenter.self), "Feed")
    }
}
