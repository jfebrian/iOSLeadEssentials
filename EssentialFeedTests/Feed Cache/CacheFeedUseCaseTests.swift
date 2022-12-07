//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Joanda Febrian on 06/12/22.
//

import XCTest
import EssentialFeed

final class CacheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        
        sut.save(uniqueImageFeed().models) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_doesNotRequestCacheInsertion_whenDeletionFailed() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError
        
        sut.save(uniqueImageFeed().models) { _ in }
        
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_requestsNewCacheInsertion_withTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let feed = uniqueImageFeed()
        
        sut.save(feed.models) { _ in }
        
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(
            store.receivedMessages,
            [.deleteCachedFeed, .insert(feed.locals, timestamp)]
        )
    }
    
    func test_save_fails_whenDeletionFailed() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError
        
        expect(sut, toCompleteWithResult: deletionError) {
            store.completeDeletion(with: deletionError)
        }
    }
    
    func test_save_fails_whenInsertionFailed() {
        let (sut, store) = makeSUT()
        let insertionError = anyNSError
        
        expect(sut, toCompleteWithResult: insertionError) {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        }
    }
    
    func test_save_succeeds_whenInsertionSucceed() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWithResult: nil) {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        }
    }
    
    func test_save_doesNotDeliverDeliverDeletionError_afterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut?.save(uniqueImageFeed().models, completion: { receivedResults.append($0) })
        
        sut = nil
        store.completeDeletion(with: anyNSError)
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    func test_save_doesNotDeliverInsertionError_afterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut?.save([uniqueImage()], completion: { receivedResults.append($0) })
        
        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: anyNSError)
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    // MARK: - Helpers
    
    private func expect(
        _ sut: LocalFeedLoader,
        toCompleteWithResult expectedResult: NSError?,
        when action: () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for save completion")
        
        var receivedResult: LocalFeedLoader.SaveResult = nil
        sut.save(uniqueImageFeed().models) { result in
            receivedResult = result
            exp.fulfill()
        }
        
        action()
        waitForExpectations(timeout: 0.1)
        
        XCTAssertEqual(receivedResult as NSError?, expectedResult, file: file, line: line)
    }
    
    private func makeSUT(
        currentDate: @escaping () -> Date = Date.init,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, store)
    }
}
