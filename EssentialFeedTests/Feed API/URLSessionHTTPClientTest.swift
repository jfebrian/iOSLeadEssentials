//
//  URLSessionHTTPClientTest.swift
//  EssentialFeedTests
//
//  Created by Joanda Febrian on 30/11/22.
//

import XCTest
import EssentialFeed

protocol HTTPSession {
    func dataTask(
        with url: URL,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> HTTPSessionTask
}

protocol HTTPSessionTask {
    func resume()
}

final class URLSessionHTTPClient {
    private let session: HTTPSession

    init(session: HTTPSession) {
        self.session = session
    }

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error { completion(.failure(error)) }
        }.resume()
    }
}

final class URLSessionHTTPClientTest: XCTestCase {
    
    func test_getFromURL_resumesDataTaskWithURL() {
        let url = URL(string: "any-url.com")!
        let sessionSpy = HTTPSessionSpy()
        let taskSpy = HTTPSessionTaskSpy()
        sessionSpy.stub(url: url, task: taskSpy)
        
        let sut = URLSessionHTTPClient(session: sessionSpy)

        sut.get(from: url) { _ in }

        XCTAssertEqual(taskSpy.resumeCallCount, 1)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let url = URL(string: "any-url.com")!
        let sessionSpy = HTTPSessionSpy()
        let error = NSError(domain: "any error", code: 1)
        sessionSpy.stub(url: url, error: error)
        
        let sut = URLSessionHTTPClient(session: sessionSpy)
        
        let exp = expectation(description: "Wait for completion")

        sut.get(from: url) { result in
            switch result {
            case let .failure(receivedError as NSError):
                XCTAssertEqual(receivedError, error)
            default: XCTFail("Expected failured with error \(error), got \(result)")
            }
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 0.1)
        
    }
    
    // MARK: - Helpers

    private class HTTPSessionSpy: HTTPSession {
        private var stubs = [URL: Stub]()
        
        private struct Stub {
            let task: HTTPSessionTask
            let error: Error?
        }
        
        func stub(
            url: URL,
            task: HTTPSessionTask = FakeHTTPSessionTask(),
            error: Error? = nil
        ) {
            stubs[url] = Stub(task: task, error: error)
        }
        
        func dataTask(
            with url: URL,
            completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
        ) -> HTTPSessionTask {
            guard let stub = stubs[url] else {
                fatalError("Couldn't find stub for \(url)")
            }
            completionHandler(nil, nil, stub.error)
            
            return stub.task
        }
    }

    private class FakeHTTPSessionTask: HTTPSessionTask {
        func resume() {}
    }
    
    private class HTTPSessionTaskSpy: HTTPSessionTask {
        private(set) var resumeCallCount = 0
        
        func resume() {
            resumeCallCount += 1
        }
    }
}
