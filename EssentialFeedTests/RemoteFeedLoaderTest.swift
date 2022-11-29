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

        expect(sut, toCompleteWith: [.failure(.connectivity)], when: {
            let clientError = NSError(domain: "Test", code: 0)
            client.callAllCompletions(with: clientError)
        })
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        let expectedResult: [RemoteFeedLoader.Result] = samples.map { _ in .failure(.invalidData) }
        
        expect(sut, toCompleteWith: expectedResult, when: {
            samples.forEach { client.callAllCompletions(withStatusCode: $0) }
        })
    }
    
    func test_load_deliversErrorOn200HTTPResponse_withInvalidJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: [.failure(.invalidData)], when: {
            let invalidJSON = Data("invalid json".utf8)
            client.callAllCompletions(withStatusCode: 200, data: invalidJSON)
        })
    }
    
    func test_load_deliversNoItemsOn200HTTPSResponse_withEmptyJSONList() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: [.success([])], when: {
            let emptyListJSON = Data("{\"items\": []}".utf8)
            client.callAllCompletions(withStatusCode: 200, data: emptyListJSON)
        })
    }
    
    func test_load_deliversItemsOn200HTTPResponse_withJSONItems() {
        let (sut, client) = makeSUT()
        
        let item1 = FeedItem(
            id: UUID(),
            description: nil,
            location: nil,
            imageURL: URL(string: "any-image-url.com")!
        )
        
        let item1JSON = [
            "id": item1.id.uuidString,
            "image": item1.imageURL.absoluteString
        ]
        
        let item2 = FeedItem(
            id: UUID(),
            description: "description",
            location: "location",
            imageURL: URL(string: "other-image-url.com")!
        )
        
        let item2JSON = [
            "id": item2.id.uuidString,
            "description": item2.description,
            "location": item2.location,
            "image": item2.imageURL.absoluteString
        ]
        
        let itemsJSON = [
            "items": [item1JSON, item2JSON]
        ]
        
        expect(sut, toCompleteWith: [.success([item1, item2])], when: {
            let json = try! JSONSerialization.data(withJSONObject: itemsJSON)
            client.callAllCompletions(withStatusCode: 200, data: json)
        })
    }
    
    private func expect(
        _ sut: RemoteFeedLoader,
        toCompleteWith results: [RemoteFeedLoader.Result],
        when action: () -> Void,
        line: UInt = #line
    ) {
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load { capturedResults.append($0) }
        
        action()
        
        XCTAssertEqual(capturedResults, results,  line: line)
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
