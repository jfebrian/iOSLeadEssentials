//
//  EssentialFeedCacheIntegrationTests.swift
//  EssentialFeedCacheIntegrationTests
//
//  Created by Joanda Febrian on 11/12/22.
//

import XCTest
import EssentialFeed

final class EssentialFeedCacheIntegrationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        setupEmptyStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        
        undoStoreSideEffects()
    }

    func test_load_deliversNoItemsOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut, toLoad: [])
    }
    
    func test_load_deliversItemsSavedOnASeparateInstance() {
        let sutToPerformSave = makeSUT()
        let sutToPerformLoad = makeSUT()
        let feed = uniqueImageFeed().models
        
        let saveExp = expectation(description: "Wait for save completion")
        sutToPerformSave.save(feed) { saveError in
            XCTAssertNil(saveError)
            saveExp.fulfill()
        }
        wait(for: [saveExp], timeout: 5)
        
        expect(sutToPerformLoad, toLoad: feed)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #file,
        line: UInt = #line
    ) -> LocalFeedLoader {
        let storeBundle = Bundle(for: CoreDataFeedStore.self)
        let storeURL = testSpecificStoreURL()
        let store = try! CoreDataFeedStore(storeURL: storeURL, bundle: storeBundle)
        let sut = LocalFeedLoader(store: store, currentDate: Date.init)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return sut
    }
    
    private func expect(
        _ sut: LocalFeedLoader,
        toLoad expectedFeed: [FeedImage],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for load completion")
        sut.load { result in
            switch result {
            case let .success(imageFeed):
                XCTAssertEqual(
                    imageFeed, expectedFeed,
                    "Expected empty image feed, got \(imageFeed) instead",
                    file: file, line: line
                )
            case let .failure(error):
                XCTFail(
                    "Expected successful feed with empty result, got failure with error \(error) instead",
                    file: file, line: line
                )
            }
            exp.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    private func testSpecificStoreURL() -> URL {
        cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }
    
    private func cachesDirectory() -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
}
