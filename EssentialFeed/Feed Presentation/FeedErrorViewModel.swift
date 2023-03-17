//
//  FeedErrorViewModel.swift
//  EssentialFeed
//
//  Created by Joanda Febrian on 17/03/23.
//

public struct FeedErrorViewModel {
    public let message: String?

    public static var noError: FeedErrorViewModel {
        return FeedErrorViewModel(message: nil)
    }
    
    public static func error(message: String) -> FeedErrorViewModel {
        return FeedErrorViewModel(message: message)
    }
}
