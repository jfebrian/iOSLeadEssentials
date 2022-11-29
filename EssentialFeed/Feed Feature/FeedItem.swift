//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Joanda Febrian on 29/11/22.
//

import Foundation

public struct FeedItem: Equatable {
    let id: UUID
    let description: String?
    let location: String?
    let imageURL: URL
}
