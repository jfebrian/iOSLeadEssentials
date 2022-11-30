//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Joanda Febrian on 29/11/22.
//

import Foundation

public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public typealias Result = Swift.Result<[FeedItem], Error>

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { result in
            switch result {
            case let .success((data, response)):
                completion(FeedItemsMapper.map(data, from: response))
            case .failure: completion(.failure(.connectivity ))
            }
        }
    }
}
