//
//  URLSessionHTTPClientTest.swift
//  EssentialFeedTests
//
//  Created by Joanda Febrian on 30/11/22.
//

import XCTest
import EssentialFeed

final class URLSessionHTTPClientTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        super.tearDown()
        
        URLProtocolStub.stopInterceptingRequests()
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
        let receivedError = resultErrorFor(data: nil, response: nil, error: error)
        
        assertNSErrorEqual(try XCTUnwrap(receivedError as? NSError), error)
    }
    
    func test_getFromURL_failsOnAllInvalidCases() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: anyHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHTTPURLResponse, error: nil))
    }
    
    func test_getFromURL_succeedsOnHTTPURLResponseWithData() {
        let data = anyData
        let response = anyHTTPURLResponse
        
        let receivedValues = resultValuesFor(data: data, response: response, error: nil)
        
        XCTAssertEqual(receivedValues?.data, data)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
    }
    
    func test_getFromURL_succeedsWithEmptyData_onHTTPURLResponseWithNilData() {
        let response = anyHTTPURLResponse
        
        let receivedValues = resultValuesFor(data: nil, response: response, error: nil)
        
        let emptyData = Data()
        XCTAssertEqual(receivedValues?.data, emptyData)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
    }
    
    func test_cancelGetFromURLTask_cancelsURLRequest() {
        let url = anyURL
        let exp = expectation(description: "Wait for request")

        let task = makeSUT().get(from: url) { result in
            switch result {
            case let .failure(error as NSError) where error.code == URLError.cancelled.rawValue:
                break

            default:
                XCTFail("Expected cancelled result, got \(result) instead")
            }
            exp.fulfill()
        }

        task.cancel()
        wait(for: [exp], timeout: 1.0)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(line: UInt = #line) -> HTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, line: line)
        return sut
    }
    
    private func resultErrorFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        line: UInt = #line
    ) -> Error? {
        let result = resultFor(data: data, response: response, error: error, line: line)
        
        switch result {
        case let .failure(error): return error
        default: XCTFail("Expected failure, got \(result) instead", line: line)
        }
        
        return nil
    }
    
    private func resultValuesFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        line: UInt = #line
    ) -> (data: Data, response: HTTPURLResponse)? {
        let result = resultFor(data: data, response: response, error: error, line: line)
        
        switch result {
        case let .success(values): return values
        default: XCTFail("Expected success, got \(result) instead", line: line)
        }
        
        return nil
    }
    
    private func resultFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        line: UInt = #line
    ) -> HTTPClientResult {
        URLProtocolStub.stub(data: data, response: response, error: error)
        
        let exp = expectation(description: "Wait for completion")

        var receivedResult: HTTPClientResult!
        makeSUT().get(from: anyURL) { result in
            receivedResult = result
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 0.1)
        
        return receivedResult
    }

    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?
        
        struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func stub(
            data: Data?,
            response: URLResponse?,
            error: Error?
        ) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(Self.self)
        }
        
        static  func stopInterceptingRequests() {
            URLProtocol.unregisterClass(Self.self)
            stub = nil
            requestObserver = nil
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            if let requestObserver = URLProtocolStub.requestObserver {
                client?.urlProtocolDidFinishLoading(self)
                return requestObserver(request)
            }
            
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
    
    private let anyData = Data("any data".utf8)
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
