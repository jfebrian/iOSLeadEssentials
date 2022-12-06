//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Joanda Febrian on 30/11/22.
//

import Foundation

final class FeedItemsMapper {
    private struct Root: Decodable {
        let items: [RemoteFeedItem]
    }
    
    private static var OK_200: Int { 200 }

    static func map(
        _ data: Data,
        from response: HTTPURLResponse
    ) throws -> [RemoteFeedItem] {
        guard response.statusCode == OK_200,
              let root = try? JSONDecoder().decode(Root.self, from: data)
        else { throw RemoteFeedLoader.Error.invalidData }
        
        return root.items
    }
}
