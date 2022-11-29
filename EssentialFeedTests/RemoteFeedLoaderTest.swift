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

        expect(sut, toCompleteWithErrors: [.connectivity], when: {
            let clientError = NSError(domain: "Test", code: 0)
            client.callAllCompletions(with: clientError)
        })
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        let expectedErrors: [RemoteFeedLoader.Error] = samples.map { _ in .invalidData }
        
        expect(sut, toCompleteWithErrors: expectedErrors, when: {
            samples.forEach { client.callAllCompletions(withStatusCode: $0) }
        })
    }
    
    func test_load_deliversErrorOn200HTTPResponse_withInvalidJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithErrors: [.invalidData], when: {
            let invalidJSON = Data("invalid json".utf8)
            client.callAllCompletions(withStatusCode: 200, data: invalidJSON)
        })
    }
    
    private func expect(
        _ sut: RemoteFeedLoader,
        toCompleteWithErrors errors: [RemoteFeedLoader.Error],
        when action: () -> Void,
        line: UInt = #line
    ) {
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { capturedErrors.append($0) }
        
        action()
        
        XCTAssertEqual(capturedErrors, errors,  line: line)
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
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        var requestedURLs: [URL] { messages.map(\.url) }

        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }
        
        func callAllCompletions(with error: Error) {
            messages.forEach { message in message.completion(.failure(error)) }
        }
        
        func callAllCompletions(withStatusCode code: Int, data: Data = Data()) {
            messages.forEach { message in
                let response = HTTPURLResponse(
                    url: message.url,
                    statusCode: code,
                    httpVersion: nil,
                    headerFields: nil
                )!
                message.completion(.success((data, response)))
            }
        }
    }
}
