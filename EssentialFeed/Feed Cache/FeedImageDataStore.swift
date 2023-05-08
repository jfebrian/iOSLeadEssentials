//
//  FeedImageDataStore.swift
//  EssentialFeed
//
//  Created by Joanda Febrian on 08/05/23.
//

import Foundation

public protocol FeedImageDataStore {
    typealias Result = Swift.Result<Data?, Error>

    func retrieve(dataForURL url: URL, completion: @escaping (Result) -> Void)
}
