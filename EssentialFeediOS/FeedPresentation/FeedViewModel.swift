//
//  FeedViewModel.swift
//  EssentialFeediOS
//
//  Created by Joanda Febrian on 28/01/23.
//

import Foundation
import EssentialFeed

final class FeedViewModel {
    typealias Observer<T> = (T) -> Void
    
    var onLoadingStateChange: Observer<Bool>?
    var onFeedLoad: Observer<[FeedImage]>?
    
    private var feedLoader: FeedLoader?
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    func loadFeed() {
        onLoadingStateChange?(true)
        feedLoader?.load { [weak self] result in
            if let feed = try? result.get() {
                self?.onFeedLoad?(feed)
            }
            self?.onLoadingStateChange?(false)
        }
    }
}
