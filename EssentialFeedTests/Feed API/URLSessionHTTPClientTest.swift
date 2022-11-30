//
//  URLSessionHTTPClientTest.swift
//  EssentialFeedTests
//
//  Created by Joanda Febrian on 30/11/22.
//

import XCTest

final class URLSessionHTTPClient {
    private let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func get(from url: URL) {
        session.dataTask(with: url) { _, _, _ in }
    }
}

final class URLSessionHTTPClientTest: XCTestCase {

    func test_getFromURL_createsDataTaskWithURL() {
        let url = URL(string: "any-url.com")!
        let sessionSpy = URLSessionSpy()
        let sut = URLSessionHTTPClient(session: sessionSpy)

        sut.get(from: url)

        XCTAssertEqual(sessionSpy.receivedURLs, [url])
    }
    
    // MARK: - Helpers

    private class URLSessionSpy: URLSession {
        private(set) var receivedURLs = [URL]()
        
        override func dataTask(
            with url: URL,
            completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
        ) -> URLSessionDataTask {
            receivedURLs.append(url)
            return FakeURLSessionDataTask()
        }
    }

    private class FakeURLSessionDataTask: URLSessionDataTask {}
}
