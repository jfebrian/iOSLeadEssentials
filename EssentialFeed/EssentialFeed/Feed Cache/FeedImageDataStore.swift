//
//  FeedImageDataStore.swift
//  EssentialFeed
//
//  Created by Joanda Febrian on 08/05/23.
//

import Foundation

public protocol FeedImageDataStore {
    typealias RetrievalResult = Result<Data?, Error>
    typealias InsertionResult = Result<Void, Error>

    func insert(_ data: Data, for url: URL, completion: @escaping (InsertionResult) -> Void)
    func retrieve(dataForURL url: URL, completion: @escaping (RetrievalResult) -> Void)
}
