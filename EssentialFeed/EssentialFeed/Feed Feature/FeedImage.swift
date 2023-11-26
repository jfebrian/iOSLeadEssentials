//
//  FeedImage.swift
//  EssentialFeed
//
//  Created by Joanda Febrian on 29/11/22.
//

import Foundation

public struct FeedImage: Hashable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let url: URL

    public init(
        id: UUID,
        description: String? = nil,
        location: String? = nil,
        url: URL
    ) {
        self.id = id
        self.description = description
        self.location = location
        self.url = url
    }
}
