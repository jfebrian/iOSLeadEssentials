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
            let json = makeItemsJSON([])
            samples.forEach { client.callAllCompletions(withStatusCode: $0, data: json) }
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
            let emptyListJSON = makeItemsJSON([] )
            client.callAllCompletions(withStatusCode: 200, data: emptyListJSON)
        })
    }
    
    func test_load_deliversItemsOn200HTTPResponse_withJSONItems() {
        let (sut, client) = makeSUT()
        
        let item1 = makeItem(
            id: UUID(),
            imageURL: URL(string: "any-image-url.com")!
        )
        
        let item2 = makeItem(
            id: UUID(),
            description: "description",
            location: "location",
            imageURL: URL(string: "other-image-url.com")!
        )
        
        let items = [item1.item, item2.item]
        
        expect(sut, toCompleteWith: [.success(items)], when: {
            let json = makeItemsJSON([item1.json, item2.json])
            client.callAllCompletions(withStatusCode: 200, data: json)
        })
    }
    
    private func makeItem(
        id: UUID,
        description: String? = nil,
        location: String? = nil,
        imageURL: URL
    ) -> (item: FeedItem, json: [String: Any]) {
        let item = FeedItem(
            id: id,
            description: description,
            location: location,
            imageURL: imageURL
        )
        let json = [
            "id": id.uuidString,
            "description": description as Any,
            "location": location as Any,
            "image": imageURL.absoluteString
        ].compactMapValues { $0 }
        
        return (item, json)
    }
    
    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let json = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)
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
        
        func callAllCompletions(withStatusCode code: Int, data: Data) {
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
