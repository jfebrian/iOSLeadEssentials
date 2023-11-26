// Created by Joanda Febrian. All rights reserved.

import XCTest
import EssentialFeed

final class SharedLocalizationTests: XCTestCase {
    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        assertLocalizedKeyAndValuesExist(in: Bundle(for: LoadResourcePresenter<Any, DummyView>.self), "Shared")
    }

    private class DummyView: ResourceView {
        func display(_ viewModel: Any) {}
    }
}
