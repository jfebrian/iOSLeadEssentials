//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Joanda Febrian on 30/11/22.
//

import Foundation

public typealias HTTPClientResult = Result<(Data, HTTPURLResponse), Error>

public protocol HTTPClientTask {
    func cancel()
}

public protocol HTTPClient {
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    @discardableResult
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) -> HTTPClientTask
}
