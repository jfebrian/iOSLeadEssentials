//
//  FeedViewAdapter.swift
//  EssentialFeediOS
//
//  Created by Joanda Febrian on 29/01/23.
//

import UIKit
import EssentialFeed
import EssentialFeediOS

final class FeedViewAdapter: FeedView {
    private weak var controller: FeedViewController?
    private let imageLoader: FeedImageDataLoader
    
    init(controller: FeedViewController, imageLoader: FeedImageDataLoader) {
        self.controller = controller
        self.imageLoader = imageLoader
    }
    
    func display(_ viewModel: FeedViewModel) {
        controller?.display(viewModel.feed.map { model in
            let adapter = FeedImageDataLoaderPresentationAdapter<
                WeakRefVirtualProxy<FeedImageCellController>,
                UIImage
            >(model: model, imageLoader: imageLoader)
            let view = FeedImageCellController(delegate: adapter)
            adapter.presenter = FeedImagePresenter(
                view: WeakRefVirtualProxy(view),
                imageTransformer: UIImage.init(data:)
            )
            return view
        })
    }
}

extension WeakRefVirtualProxy: FeedImageView where T: FeedImageView, T.Image == UIImage {
    func display(_ model: FeedImageViewModel<UIImage>) {
        object?.display(model)
    }
}

private final class FeedImageDataLoaderPresentationAdapter<View: FeedImageView, Image>:
    FeedImageCellControllerDelegate where View.Image == Image {
    
    private let model: FeedImage
    private let imageLoader: FeedImageDataLoader
    private var task: FeedImageDataLoaderTask?
    
    var presenter: FeedImagePresenter<View, Image>?
    
    init(model: FeedImage, imageLoader: FeedImageDataLoader) {
        self.model = model
        self.imageLoader = imageLoader
    }
    
    deinit { cancelTask() }
    
    func didRequestImage() {
        presenter?.didStartLoadingImageData(for: model)
        task = imageLoader.loadImageData(from: model.url) { [weak self] result in
            self?.handle(result)
        }
    }
    
    private func handle(_ result: FeedImageDataLoader.Result) {
        switch result {
        case let .success(data):
            presenter?.didFinishLoadingImageData(with: data, for: model)
        case let .failure(error):
            presenter?.didFinishLoadingImageData(with: error, for: model)
        }
    }
    
    func didCancelImageRequest() {
        cancelTask()
    }
    
    private func cancelTask() {
        task?.cancel()
    }
}
