//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Joanda Febrian on 29/11/22.
//

import Foundation

public typealias LoadFeedResult<Error: Swift.Error> = Result<[FeedItem], Error>

protocol FeedLoader {
    associatedtype Error: Swift.Error
    
    func load(completion: @escaping (LoadFeedResult<Error>) -> Void)
}
