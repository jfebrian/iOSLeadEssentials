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
        expect(sut, toRetrieve: .success(.none), file: file, line: line)
    }
    
    func assert_retrieve_hasNoSideEffectsOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(sut, toRetrieveTwice: .success(.none), file: file, line: line)
    }
    
    func assert_retrieve_deliversFoundValuesOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let cache = makeCache()
        
        insert(cache: cache, to: sut)
        
        expect(sut, toRetrieve: .success(cache), file: file, line: line)
    }
    
    func assert_retrieve_hasNoSideEffectsOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let cache = makeCache()
        
        insert(cache: cache, to: sut)
        
        expect(sut, toRetrieveTwice: .success(cache), file: file, line: line)
    }
    
    func assert_insert_deliversNoErrorOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let insertionError = insert(cache: makeCache(), to: sut)
        
        XCTAssertNil(insertionError, "Expected to insert cache successfully", file: file, line: line)
    }
    
    func assert_insert_deliversNoErrorOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        insert(cache: makeCache(), to: sut)
        
        let insertionError = insert(cache: makeCache(), to: sut)
        
        XCTAssertNil(insertionError, "Expected to insert cache successfully", file: file, line: line)
    }
    
    func assert_insert_overridesPreviouslyInsertedCacheValues(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        insert(cache: makeCache(), to: sut)
        
        let latestCache = makeCache()
        insert(cache: latestCache, to: sut)
        
        expect(sut, toRetrieve: .success(latestCache), file: file, line: line)
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
        
        expect(sut, toRetrieve: .success(.none), file: file, line: line)
    }
    
    func assert_delete_deliversNoErrorOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        insert(cache: makeCache(), to: sut)
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed", file: file, line: line)
    }
    
    func assert_delete_emptiesPreviouslyInsertedCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        insert(cache: makeCache(), to: sut)
        
        deleteCache(from: sut)
        
        expect(sut, toRetrieve: .success(.none), file: file, line: line)
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
    func insert(cache: CachedFeed, to sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache insertion")
        var insertionError: Error?
        sut.insert(cache.feed, timestamp: cache.timestamp) { result in
            if case let .failure(error) = result { insertionError = error }
            exp.fulfill()
        }
        waitForExpectations(timeout: 0.1)
        return insertionError
    }
    
    @discardableResult
    func deleteCache(from sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache insertion")
        var deletionError: Error?
        sut.deleteCachedFeed { result in
            if case let .failure(error) = result { deletionError = error }
            exp.fulfill()
        }
        waitForExpectations(timeout: 3)
        return deletionError
    }
    
    func expect(
        _ sut: FeedStore,
        toRetrieve expectedResult: FeedStore.RetrievalResult,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for cache retrieval")
        
        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
            case (.success(.none), .success(.none)),
                 (.failure, .failure):
                break
            case let (.success(.some(expectedCache)), .success(.some(retrievedCache))):
                XCTAssertEqual(expectedCache.feed, retrievedCache.feed, file: file, line: line)
                XCTAssertEqual(expectedCache.timestamp, retrievedCache.timestamp, file: file, line: line)
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
        toRetrieveTwice expectedResult: FeedStore.RetrievalResult,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }
    
    func makeCache() -> CachedFeed {
        let feed = uniqueImageFeed().locals
        let timestamp = Date()
        return CachedFeed(feed: feed, timestamp: timestamp)
    }
}
