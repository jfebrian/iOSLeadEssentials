//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Joanda Febrian on 11/12/22.
//

import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {
    @discardableResult
    func insert(feed: [LocalFeedImage], timestamp: Date, to sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache insertion")
        var insertionError: Error?
        sut.insert(feed, timestamp: timestamp) { receivedInsertionError in
            insertionError = receivedInsertionError
            exp.fulfill()
        }
        waitForExpectations(timeout: 0.1)
        return insertionError
    }
    
    @discardableResult
    func deleteCache(from sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache insertion")
        var deletionError: Error?
        sut.deleteCachedFeed { receivedDeletionError in
            deletionError = receivedDeletionError
            exp.fulfill()
        }
        waitForExpectations(timeout: 3)
        return deletionError
    }
    
    func expect(
        _ sut: FeedStore,
        toRetrieve expectedResult: RetriveCachedFeedResult,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for cache retrieval")
        
        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
            case (.empty, .empty),
                 (.failure, .failure):
                break
            case let (.found(expectedFeed, expectedTimestamp), .found(retrievedFeed, retrievedTimestamp)):
                XCTAssertEqual(expectedFeed, retrievedFeed, line: line)
                XCTAssertEqual(expectedTimestamp, retrievedTimestamp, line: line)
            default:
                XCTFail(
                    "Expected to retrieve \(expectedResult), got \(retrievedResult) instead",
                    line: line
                )
            }
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 0.1)
    }
    
    func expect(
        _ sut: FeedStore,
        toRetrieveTwice expectedResult: RetriveCachedFeedResult,
        line: UInt = #line
    ) {
        expect(sut, toRetrieve: expectedResult, line: line)
        expect(sut, toRetrieve: expectedResult, line: line)
    }
}
