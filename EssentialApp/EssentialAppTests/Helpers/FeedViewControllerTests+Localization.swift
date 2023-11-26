//
//  FeedViewControllerTests+Localization.swift
//  EssentialFeediOSTests
//
//  Created by Joanda Febrian on 22/02/23.
//

import Foundation
import XCTest
import EssentialFeed

extension FeedUIIntegrationTests {
    private class DummyView: ResourceView {
        func display(_ viewModel: Any) {}
    }

    var loadError: String {
        LoadResourcePresenter<Any, DummyView>.loadError
    }

    var feedTitle: String {
        FeedPresenter.title
    }
}
