//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Joanda Febrian on 29/11/22.
//

import Foundation

typealias LoadFeedResult = Result<[FeedItem], Error>

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
