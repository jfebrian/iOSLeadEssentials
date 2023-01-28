//
//  FeedUIComposer.swift
//  EssentialFeediOS
//
//  Created by Joanda Febrian on 28/01/23.
//

import Foundation
import EssentialFeed

public final class FeedUIComposer {
    private init() {}
    
    public static func feedComposedWith(
        feedLoader: FeedLoader,
        imageLoader: FeedImageDataLoader
    ) -> FeedViewController {
        let refreshController = FeedRefreshViewController(feedLoader: feedLoader)
        let feedController = FeedViewController(refreshController: refreshController)
        refreshController.onRefresh = adaptFeedToCellControllers(
            forwardingTo: feedController, loader: imageLoader
        )
        return feedController
    }
    
    private static func adaptFeedToCellControllers(
        forwardingTo controller: FeedViewController,
        loader: FeedImageDataLoader
    ) -> (([FeedImage]) -> Void) {
        return { [weak controller] feed in
            controller?.tableModel = feed.map { model in
                FeedImageCellController(model: model, imageLoader: loader)
            }
        }
    }
}
