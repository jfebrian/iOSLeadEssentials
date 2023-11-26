//
//  FeedImageViewModel.swift
//  EssentialFeed
//
//  Created by Joanda Febrian on 17/03/23.
//

public struct FeedImageViewModel {
    public let description: String?
    public let location: String?

    public var hasLocation: Bool { location != nil }
}
