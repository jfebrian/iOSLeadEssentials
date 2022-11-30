//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Joanda Febrian on 30/11/22.
//

import Foundation

public typealias HTTPClientResult = Result<(Data, HTTPURLResponse), Error>

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
