//
//  URLSessionHTTPClientTest.swift
//  EssentialFeedTests
//
//  Created by Joanda Febrian on 30/11/22.
//

import XCTest
import EssentialFeed

final class URLSessionHTTPClientTest: XCTestCase {
    
    override func tearDown() {
        super.tearDown()
        
        URLProtocolStub.removeStub()
    }
    
    func test_getFromURL_performsGETRequestWithURL() {
        let url = URL(string: "http://get-request-url.com/")!
        
        let exp = expectation(description: "Wait for request")
        
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        makeSUT().get(from: url) { _ in }
        
        waitForExpectations(timeout: 0.1)
    }
    
    func test_getFromURL_failsOnRequestError() throws {
        let error = anyNSError
        let receivedError = resultErrorFor((data: nil, response: nil, error: error))
        
        assertNSErrorEqual(try XCTUnwrap(receivedError as? NSError), error)
    }
    
    func test_getFromURL_failsOnAllInvalidCases() {
        XCTAssertNotNil(resultErrorFor((data: nil, response: nil, error: nil)))
        XCTAssertNotNil(resultErrorFor((data: nil, response: nonHTTPURLResponse, error: nil)))
        XCTAssertNotNil(resultErrorFor((data: anyData, response: nil, error: nil)))
        XCTAssertNotNil(resultErrorFor((data: anyData, response: nil, error: anyError)))
        XCTAssertNotNil(resultErrorFor((data: nil, response: nonHTTPURLResponse, error: anyError)))
        XCTAssertNotNil(resultErrorFor((data: nil, response: anyHTTPURLResponse, error: anyError)))
        XCTAssertNotNil(resultErrorFor((data: anyData, response: nonHTTPURLResponse, error: anyError)))
        XCTAssertNotNil(resultErrorFor((data: anyData, response: anyHTTPURLResponse, error: anyError)))
        XCTAssertNotNil(resultErrorFor((data: anyData, response: nonHTTPURLResponse, error: nil)))
    }
    
    func test_getFromURL_succeedsOnHTTPURLResponseWithData() {
        let data = anyData
        let response = anyHTTPURLResponse
        
        let receivedValues = resultValuesFor((data: data, response: response, error: nil))
        
        XCTAssertEqual(receivedValues?.data, data)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
    }
    
    func test_getFromURL_succeedsWithEmptyData_onHTTPURLResponseWithNilData() {
        let response = anyHTTPURLResponse
        
        let receivedValues = resultValuesFor((data: nil, response: response, error: nil))
        
        let emptyData = Data()
        XCTAssertEqual(receivedValues?.data, emptyData)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
    }
    
    func test_cancelGetFromURLTask_cancelsURLRequest() {
        let receivedError = resultErrorFor(taskHandler: { $0.cancel() }) as NSError?
        
        XCTAssertEqual(receivedError?.code, URLError.cancelled.rawValue)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(line: UInt = #line) -> HTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)

        let sut = URLSessionHTTPClient(session: session)
        trackForMemoryLeaks(sut, line: line)
        return sut
    }
    
    private func resultErrorFor(
        _ values: (data: Data?, response: URLResponse?, error: Error?)? = nil,
        taskHandler: (HTTPClientTask) -> Void = { _ in },
        line: UInt = #line
    ) -> Error? {
        let result = resultFor(values, taskHandler: taskHandler, line: line)
        
        switch result {
        case let .failure(error): return error
        default: XCTFail("Expected failure, got \(result) instead", line: line)
        }
        
        return nil
    }
    
    private func resultValuesFor(
        _ values: (data: Data?, response: URLResponse?, error: Error?),
        taskHandler: (HTTPClientTask) -> Void = { _ in },
        line: UInt = #line
    ) -> (data: Data, response: HTTPURLResponse)? {
        let result = resultFor(values, taskHandler: taskHandler, line: line)
        
        switch result {
        case let .success(values): return values
        default: XCTFail("Expected success, got \(result) instead", line: line)
        }
        
        return nil
    }
    
    private func resultFor(
        _ values: (data: Data?, response: URLResponse?, error: Error?)?,
        taskHandler: (HTTPClientTask) -> Void = { _ in },
        line: UInt = #line
    ) -> HTTPClient.Result {
        values.map { URLProtocolStub.stub(data: $0, response: $1, error: $2) }
        
        let exp = expectation(description: "Wait for completion")

        var receivedResult: HTTPClient.Result!
        taskHandler(makeSUT().get(from: anyURL) { result in
            receivedResult = result
            exp.fulfill()
        })
        
        waitForExpectations(timeout: 0.1)
        
        return receivedResult
    }

    private class URLProtocolStub: URLProtocol {
        struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
            let requestObserver: ((URLRequest) -> Void)?
        }
        
        private static var _stub: Stub?
        private static var stub: Stub? {
            get { return queue.sync { _stub } }
            set { queue.sync { _stub = newValue } }
        }

        private static let queue = DispatchQueue(label: "URLProtocolStub.queue")
        
        static func stub(
            data: Data?,
            response: URLResponse?,
            error: Error?
        ) {
            stub = Stub(data: data, response: response, error: error, requestObserver: nil)
        }
        
        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            stub = Stub(data: nil, response: nil, error: nil, requestObserver: observer)
        }
        
        static func removeStub() {
            stub = nil
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            guard let stub = URLProtocolStub.stub else { return }
            
            if let data = stub.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = stub.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            } else {
                client?.urlProtocolDidFinishLoading(self)
            }
            
            stub.requestObserver?(request)
        }
        
        override func stopLoading() {}
    }
    
    private let anyError: Error = NSError(domain: "any error", code: 0)
    private let anyHTTPURLResponse = HTTPURLResponse()
    private var nonHTTPURLResponse: URLResponse {
        URLResponse(
            url: anyURL,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )
    }
}
