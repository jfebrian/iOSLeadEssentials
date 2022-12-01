//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Joanda Febrian on 01/12/22.
//

import Foundation

public final class URLSessionHTTPClient: HTTPClient {
    private let session = URLSession.shared
    
    public init() {}
    
    private struct UnexpectedValuesError: Error {}

    public func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error {
                completion(.failure(error))
            } else if let data, let response = response as? HTTPURLResponse {
                completion(.success((data, response)))
            } else {
                completion(.failure(UnexpectedValuesError()))
            }
        }.resume()
    }
}
