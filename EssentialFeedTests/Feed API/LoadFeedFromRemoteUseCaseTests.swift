//
//  RemoteFeedLoaderTest.swift
//  EssentialFeedTests
//
//  Created by Joanda Febrian on 29/11/22.
//

import EssentialFeed
import XCTest

final class LoadFeedFromRemoteUseCaseTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()

        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    func test_load_requestDataFromURL() {
        let url = anyURL
        let (sut, client) = makeSUT(url: url)

        sut.load { _ in }

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadTwice_requestDataFromURLTwice() {
        let url = anyURL
        let (sut, client) = makeSUT(url: url)

        sut.load { _ in }
        sut.load { _ in }

        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: [failure(.connectivity)], when: {
            let clientError = NSError(domain: "Test", code: 0)
            client.callAllCompletions(with: clientError)
        })
    }

    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()

        let samples = [199, 201, 300, 400, 500]
        let expectedResult: [RemoteFeedLoader.Result] = samples.map { _ in
            failure(.invalidData)
        }

        expect(sut, toCompleteWith: expectedResult, when: {
            let json = makeItemsJSON([])
            samples.forEach { client.callAllCompletions(withStatusCode: $0, data: json) }
        })
    }

    func test_load_deliversErrorOn200HTTPResponse_withInvalidJSON() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: [failure(.invalidData)], when: {
            let invalidJSON = Data("invalid json".utf8)
            client.callAllCompletions(withStatusCode: 200, data: invalidJSON)
        })
    }

    func test_load_deliversNoItemsOn200HTTPSResponse_withEmptyJSONList() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: [.success([])], when: {
            let emptyListJSON = makeItemsJSON([])
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

    func test_load_doesNotDeliverResult_afterSUTInstanceHasBeenDeallocated() {
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: anyURL, client: client)

        var capturedResults = [RemoteFeedLoader.Result]()
        sut?.load { capturedResults.append($0) }

        sut = nil
        client.callAllCompletions(withStatusCode: 200, data: makeItemsJSON([]))

        XCTAssertTrue(capturedResults.isEmpty)
    }

    private func makeItem(
        id: UUID,
        description: String? = nil,
        location: String? = nil,
        imageURL: URL
    ) -> (item: FeedImage, json: [String: Any]) {
        let item = FeedImage(
            id: id,
            description: description,
            location: location,
            url: imageURL
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

        zip(capturedResults, results).forEach { capturedResult, expectedResult in
            switch (capturedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, line: line)
            case let (
                .failure(receivedError as RemoteFeedLoader.Error),
                .failure(expectedError as RemoteFeedLoader.Error)
            ): XCTAssertEqual(receivedError, expectedError, line: line)
            default:
                XCTFail(
                    "Expected result \(expectedResult), got \(capturedResult) instead.",
                    line: line
                )
            }
        }

        XCTAssertEqual(capturedResults.count, results.count, line: line)
    }

    // MARK: - Helpers

    private func makeSUT(
        url: URL = URL(string: "https://default-string.com/")!,
        line: UInt = #line
    ) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        trackForMemoryLeaks(sut, line: line)
        trackForMemoryLeaks(client, line: line)
        return (sut, client)
    }
    
    private func failure(_ error: RemoteFeedLoader.Error) -> LoadFeedResult {
        .failure(error)
    }

    private class HTTPClientSpy: HTTPClient {
        private struct Task: HTTPClientTask {
            func cancel() {}
        }
        
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()

        var requestedURLs: [URL] { messages.map(\.url) }

        func get(
            from url: URL,
            completion: @escaping (HTTPClientResult) -> Void
        ) -> HTTPClientTask {
            messages.append((url, completion))
            return Task()
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
