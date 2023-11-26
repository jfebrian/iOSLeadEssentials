// Created by Joanda Febrian. All rights reserved.

import Combine
import Foundation
import EssentialFeed
import EssentialFeediOS

final class FeedImageDataLoaderPresentationAdapter<View: FeedImageView, Image>:
    FeedImageCellControllerDelegate where View.Image == Image {

    private let model: FeedImage
    private let imageLoader: (URL) -> FeedImageDataLoader.Publisher
    private var cancellable: Cancellable?

    var presenter: FeedImagePresenter<View, Image>?

    init(model: FeedImage, imageLoader: @escaping (URL) -> FeedImageDataLoader.Publisher) {
        self.model = model
        self.imageLoader = imageLoader
    }

    func didRequestImage() {
        presenter?.didStartLoadingImageData(for: model)
        cancellable = imageLoader(model.url)
            .dispatchOnMainQueue()
            .sink(
                receiveCompletion: { [weak self] in self?.handle(completion: $0) },
                receiveValue: { [weak self] in self?.handle(data: $0) }
            )
    }

    private func handle(completion: Subscribers.Completion<Error>) {
        switch completion {
        case .finished: break
        case let .failure(error):
            presenter?.didFinishLoadingImageData(with: error, for: model)
        }
    }

    private func handle(data: Data) {
        presenter?.didFinishLoadingImageData(with: data, for: model)
    }

    func didCancelImageRequest() {
        cancellable?.cancel()
    }
}
