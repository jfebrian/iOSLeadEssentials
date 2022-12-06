//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Joanda Febrian on 06/12/22.
//

import Foundation

struct RemoteFeedItem: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}
