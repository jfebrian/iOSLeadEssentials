//
//  RemoteFeedLoaderTest.swift
//  EssentialFeedTests
//
//  Created by Joanda Febrian on 29/11/22.
//

import EssentialFeed
import XCTest

final class RemoteFeedLoaderTest: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()

        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    func test_load_requestDataFromURL() {
        let url = URL(string: "https://any-url.com/")!
        let (sut, client) = makeSUT(url: url)

        sut.load { _ in }

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadTwice_requestDataFromURLTwice() {
        let url = URL(string: "https://any-url.com/")!
        let (sut, client) = makeSUT(url: url)

        sut.load { _ in }
        sut.load { _ in }

        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()

        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { capturedErrors.append($0) }
        
        let clientError = NSError(domain: "Test", code: 0)
        client.callAllCompletions(with: clientError)

        XCTAssertEqual(capturedErrors, [.connectivity])
    }

    // MARK: - Helpers

    private func makeSUT(
        url: URL = URL(string: "https://default-string.com/")!
    ) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }

    private class HTTPClientSpy: HTTPClient {
        private var messages = [(url: URL, completion: (Error) -> Void)]()
        
        var requestedURLs: [URL] { messages.map(\.url) }

        func get(from url: URL, completion: @escaping (Error) -> Void) {
            messages.append((url, completion))
        }
        
        func callAllCompletions(with error: Error) {
            messages.forEach { message in message.completion(error) }
        }
    }
}
