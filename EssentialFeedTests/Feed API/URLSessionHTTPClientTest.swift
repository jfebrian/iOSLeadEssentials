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

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error { completion(.failure(error)) }
        }.resume()
    }
}

final class URLSessionHTTPClientTest: XCTestCase {
    
    func test_getFromURL_failsOnRequestError() {
        URLProtocolStub.startInterceptingRequests()
        
        let error = NSError(domain: "any error", code: 1)
        URLProtocolStub.stub(data: nil, response: nil, error: error)
        
        let sut = URLSessionHTTPClient()
        
        let exp = expectation(description: "Wait for completion")

        sut.get(from: .anyURL()) { result in
            switch result {
            case let .failure(receivedError as NSError):
                assertNSErrorEqual(receivedError, error)
            default: XCTFail("Expected failured with error \(error), got \(result)")
            }
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 0.1)
        
        URLProtocolStub.stopInterceptingRequests()
    }
    
    // MARK: - Helpers

    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        
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
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(Self.self)
        }
        
        static  func stopInterceptingRequests() {
            URLProtocol.unregisterClass(Self.self)
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
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
}

private extension URL {
    static func anyURL() -> URL {
        URL(string: "http://any-url.com/")!
    }
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
