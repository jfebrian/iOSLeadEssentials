//
//  FeedImagePresenter.swift
//  EssentialFeed
//
//  Created by Joanda Febrian on 17/03/23.
//

public final class FeedImagePresenter {
    public static func map(_ image: FeedImage) -> FeedImageViewModel {
        FeedImageViewModel(
            description: image.description,
            location: image.location
        )
    }
}
