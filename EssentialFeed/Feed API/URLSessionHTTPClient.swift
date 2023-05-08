//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Joanda Febrian on 01/12/22.
//

import Foundation

public final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    public init(session: URLSession) {
        self.session = session
    }
    
    private struct UnexpectedValuesError: Error {}
    
    private struct URLSessionTaskWrapper: HTTPClientTask {
        let wrapped: URLSessionTask

        func cancel() {
            wrapped.cancel()
        }
    }

    public func get(
        from url: URL,
        completion: @escaping (HTTPClientResult) -> Void
    ) -> HTTPClientTask {
        let task = session.dataTask(with: url) { data, response, error in
            completion(Result {
                if let error {
                    throw error
                } else if let data, let response = response as? HTTPURLResponse {
                    return (data, response)
                } else {
                    throw UnexpectedValuesError()
                }
            })
        }
        task.resume()
        return URLSessionTaskWrapper(wrapped: task)
    }
}
