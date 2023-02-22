//
//  FeedUIComposer.swift
//  EssentialFeediOS
//
//  Created by Joanda Febrian on 28/01/23.
//

import UIKit
import EssentialFeed

public final class FeedUIComposer {
    private init() {}
    
    public static func feedComposedWith(
        feedLoader: FeedLoader,
        imageLoader: FeedImageDataLoader
    ) -> FeedViewController {
        let presentationAdapter = FeedLoaderPresentationAdapter(feedLoader: feedLoader)
        
        let bundle = Bundle(for: FeedViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let feedController = storyboard.instantiateInitialViewController() as! FeedViewController
        let refreshController = feedController.refreshController!
        refreshController.delegate = presentationAdapter
        
        let feedPresenter = FeedPresenter(
            feedView: FeedViewAdapter(controller: feedController, imageLoader: imageLoader),
            loadingView: WeakRefVirtualProxy(refreshController)
        )
        presentationAdapter.presenter = feedPresenter
        return feedController
    }
}
