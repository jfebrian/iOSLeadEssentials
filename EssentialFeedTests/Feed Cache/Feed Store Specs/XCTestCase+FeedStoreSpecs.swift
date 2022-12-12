//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Joanda Febrian on 11/12/22.
//

import XCTest
import EssentialFeed

// MARK: - Assertion Functions

extension FeedStoreSpecs where Self: XCTestCase {
    func assert_retrieve_deliversEmptyOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(sut, toRetrieve: .success(.empty), file: file, line: line)
    }
    
    func assert_retrieve_hasNoSideEffectsOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(sut, toRetrieveTwice: .success(.empty), file: file, line: line)
    }
    
    func assert_retrieve_deliversFoundValuesOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {

        let (feed, timestamp) = makeCache()
        
        insert(feed: feed, timestamp: timestamp, to: sut)
        
        expect(sut, toRetrieve: .success(.found(feed: feed, timestamp: timestamp)), file: file, line: line)
    }
    
    func assert_retrieve_hasNoSideEffectsOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let (feed, timestamp) = makeCache()
        
        insert(feed: feed, timestamp: timestamp, to: sut)
        
        expect(sut, toRetrieveTwice: .success(.found(feed: feed, timestamp: timestamp)), file: file, line: line)
    }
    
    func assert_insert_deliversNoErrorOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let insertionError = insert(feed: uniqueImageFeed().locals, timestamp: Date(), to: sut)
        
        XCTAssertNil(insertionError, "Expected to insert cache successfully", file: file, line: line)
    }
    
    func assert_insert_deliversNoErrorOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        insert(feed: uniqueImageFeed().locals, timestamp: Date(), to: sut)
        
        let insertionError = insert(feed: uniqueImageFeed().locals, timestamp: Date(), to: sut)
        
        XCTAssertNil(insertionError, "Expected to insert cache successfully", file: file, line: line)
    }
    
    func assert_insert_overridesPreviouslyInsertedCacheValues(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        insert(feed: uniqueImageFeed().locals, timestamp: Date(), to: sut)
        
        let (latestFeed, latestTimestamp) = makeCache()
        insert(feed: latestFeed, timestamp: latestTimestamp, to: sut)
        
        expect(sut, toRetrieve: .success(.found(feed: latestFeed, timestamp: latestTimestamp)), file: file, line: line)
    }
    
    func assert_delete_deliversNoErrorOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError, "Expected empty cache deletion to succeed", file: file, line: line)
    }
    
    func assert_delete_hasNoSideEffectsOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        deleteCache(from: sut)
        
        expect(sut, toRetrieve: .success(.empty), file: file, line: line)
    }
    
    func assert_delete_deliversNoErrorOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        insert(feed: uniqueImageFeed().locals, timestamp: Date(), to: sut)
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed", file: file, line: line)
    }
    
    func assert_delete_emptiesPreviouslyInsertedCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        insert(feed: uniqueImageFeed().locals, timestamp: Date(), to: sut)
        
        deleteCache(from: sut)
        
        expect(sut, toRetrieve: .success(.empty), file: file, line: line)
    }
    
    func assert_storeSideEffects_runSerially(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        var completedOperationsInOrder = [XCTestExpectation]()
        
        let op1 = expectation(description: "Wait for operation 1")
        sut.insert(uniqueImageFeed().locals, timestamp: Date()) { _ in
            completedOperationsInOrder.append(op1)
            op1.fulfill()
        }
        
        let op2 = expectation(description: "Wait for operation 2")
        sut.deleteCachedFeed { _ in
            completedOperationsInOrder.append(op2)
            op2.fulfill()
        }
        
        
        let op3 = expectation(description: "Wait for operation 3")
        sut.insert(uniqueImageFeed().locals, timestamp: Date()) { _ in
            completedOperationsInOrder.append(op3)
            op3.fulfill()
        }
        
        waitForExpectations(timeout: 0.1)
        
        XCTAssertEqual(
            completedOperationsInOrder, [op1, op2, op3],
            "Expected side-effects to run serially but operations finished in the wrong order",
            file: file, line: line
        )
    }
}

// MARK: - Helper Functions

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
        toRetrieve expectedResult: RetrievalResult,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for cache retrieval")
        
        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
            case (.success(.empty), .success(.empty)),
                 (.failure, .failure):
                break
            case let (.success(.found(expectedFeed, expectedTimestamp)), .success(.found(retrievedFeed, retrievedTimestamp))):
                XCTAssertEqual(expectedFeed, retrievedFeed, file: file, line: line)
                XCTAssertEqual(expectedTimestamp, retrievedTimestamp, file: file, line: line)
            default:
                XCTFail(
                    "Expected to retrieve \(expectedResult), got \(retrievedResult) instead",
                    file: file, line: line
                )
            }
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 0.1)
    }
    
    func expect(
        _ sut: FeedStore,
        toRetrieveTwice expectedResult: RetrievalResult,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }
    
    func makeCache() -> (feed: [LocalFeedImage], timestamp: Date) {
        let feed = uniqueImageFeed().locals
        let timestamp = Date()
        return (feed, timestamp)
    }
}
