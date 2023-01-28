//
//  FeedViewModel.swift
//  EssentialFeediOS
//
//  Created by Joanda Febrian on 28/01/23.
//

import Foundation
import EssentialFeed

final class FeedViewModel {
    var onChange: ((FeedViewModel) -> Void)?
    var onFeedLoad: (([FeedImage]) -> Void)?
    
    private var feedLoader: FeedLoader?
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    private(set) var isLoading: Bool = false {
        didSet { onChange?(self) }
    }
    
    func loadFeed() {
        isLoading = true
        feedLoader?.load { [weak self] result in
            if let feed = try? result.get() {
                self?.onFeedLoad?(feed)
            }
            self?.isLoading = false
        }
    }
}
