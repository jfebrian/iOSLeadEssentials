//
//  URLSessionHTTPClientTest.swift
//  EssentialFeedTests
//
//  Created by Joanda Febrian on 30/11/22.
//

import XCTest
import EssentialFeed

final class URLSessionHTTPClient {
    private let session = URLSession.shared
    
    struct UnexpectedValuesError: Error {}

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
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
        
        URLProtocolStub.stub(data: data, response: response, error: nil)
        
        let exp = expectation(description: "Wait for comlpetion")
        
        makeSUT().get(from: .anyURL()) { result in
            switch result {
            case let .success((receivedData, receivedResponse)):
                XCTAssertEqual(receivedData, data)
                XCTAssertEqual(receivedResponse.url, response.url)
                XCTAssertEqual(receivedResponse.statusCode, response.statusCode)
            default:
                XCTFail("Expected success, got \(result) instead")
            }
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 0.1)
    }
    
    func test_getFromURL_succeedsWithEmptyData_onHTTPURLResponseWithNilData() {
        let response = anyHTTPURLResponse
        URLProtocolStub.stub(data: nil, response: response, error: nil)
        
        let exp = expectation(description: "Wait for comlpetion")
        
        makeSUT().get(from: .anyURL()) { result in
            switch result {
            case let .success((receivedData, receivedResponse)):
                let emptyData = Data()
                XCTAssertEqual(receivedData, emptyData)
                XCTAssertEqual(receivedResponse.url, response.url)
                XCTAssertEqual(receivedResponse.statusCode, response.statusCode)
            default:
                XCTFail("Expected success, got \(result) instead")
            }
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 0.1)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(line: UInt = #line) -> URLSessionHTTPClient {
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
        URLProtocolStub.stub(data: data, response: response, error: error)
        
        let exp = expectation(description: "Wait for completion")

        var receivedError: Error?
        makeSUT().get(from: .anyURL()) { result in
            switch result {
            case let .failure(error): receivedError = error
            default: XCTFail("Expected failure, got \(result)", line: line)
            }
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 0.1)
        
        return receivedError
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
            requestObserver?(request)
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
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
    
    private let anyData = Data("any data".utf8)
    private let anyError: Error = NSError(domain: "any error", code: 0)
    private let anyNSError = NSError(domain: "any error", code: 0)
    private let anyHTTPURLResponse = HTTPURLResponse()
    private let nonHTTPURLResponse = URLResponse(
        url: .anyURL(),
        mimeType: nil,
        expectedContentLength: 0,
        textEncodingName: nil
    )
}

func assertNSErrorEqual(
    _ receivedError: NSError,
    _ expectedError: NSError,
    line: UInt = #line
) {
    XCTAssertEqual(
        receivedError.domain, expectedError.domain,
        "Expected error with domain \(expectedError.domain), got \(receivedError.domain)",
        line: line
    )
    
    XCTAssertEqual(
        receivedError.code, expectedError.code,
        "Expected error with code \(expectedError.code), got \(receivedError.code)",
        line: line
    )
}
