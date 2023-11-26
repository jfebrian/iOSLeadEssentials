//
//  CoreDataFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Joanda Febrian on 11/12/22.
//

import XCTest
import CoreData
import EssentialFeed

final class CoreDataFeedStoreTests: XCTestCase, FeedStoreSpecs, FailableFeedStoreSpecs {
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        
        assert_retrieve_deliversEmptyOnEmptyCache(on: sut)
    }
     
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        assert_retrieve_hasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        
        assert_retrieve_deliversFoundValuesOnNonEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        
        assert_retrieve_hasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_retrieve_deliversFailureOnRetrievalError() {
        let stub = NSManagedObjectContext.alwaysFailingFetchStub()
        stub.startIntercepting()

        let sut = makeSUT()

        assert_retrieve_deliversFailureOnRetrievalError(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnRetrievalError() {
        let stub = NSManagedObjectContext.alwaysFailingFetchStub()
        stub.startIntercepting()

        let sut = makeSUT()

        assert_retrieve_hasNoSideEffectsOnRetrievalError(on: sut)
    }
    
    func test_insert_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()
        
        assert_insert_deliversNoErrorOnEmptyCache(on: sut)
    }
    
    func test_insert_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()
        
        assert_insert_deliversNoErrorOnNonEmptyCache(on: sut)
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()
        
        assert_insert_overridesPreviouslyInsertedCacheValues(on: sut)
    }
    
    func test_insert_deliversErrorOnInsertionError() {
        let stub = NSManagedObjectContext.alwaysFailingSaveStub()
        stub.startIntercepting()
        
        let sut = makeSUT()
        
        assert_insert_deliversErrorOnInsertionError(on: sut)
    }
    
    func test_insert_hasNoSideEffectsOnInsertionError_onEmptyCache() {
        let stub = NSManagedObjectContext.alwaysFailingSaveStub()
        stub.startIntercepting()
        
        let sut = makeSUT()
        
        assert_insert_hasNoSideEffectsOnInsertionError(on: sut, with: nil)
    }
    
    func test_insert_hasNoSideEffectsOnInsertionError_onNonEmptyCache() {
        let stub = NSManagedObjectContext.alwaysFailingSaveStub()
        let cache = makeCache()
        let sut = makeSUT()

        insert(cache: cache, to: sut)
        
        stub.startIntercepting()
        
        assert_insert_hasNoSideEffectsOnInsertionError(on: sut, with: cache)
    }
    
    func test_delete_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()
        
        assert_delete_deliversNoErrorOnEmptyCache(on: sut)
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        assert_delete_hasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_delete_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()
        
        assert_delete_deliversNoErrorOnNonEmptyCache(on: sut)
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        
        assert_delete_emptiesPreviouslyInsertedCache(on: sut)
    }
    
    func test_delete_deliversErrorOnDeletionError() {
        let stub = NSManagedObjectContext.alwaysFailingSaveStub()
        let sut = makeSUT()

        insert(cache: makeCache(), to: sut)

        stub.startIntercepting()

        assert_delete_deliversErrorOnDeletionError(on: sut)
    }
    
    func test_delete_hasNoSideEffectsOnDeletionError_onEmptyCache() {
        let stub = NSManagedObjectContext.alwaysFailingSaveStub()
        stub.startIntercepting()
        
        let sut = makeSUT()

        assert_delete_hasNoSideEffectsOnDeletionError(on: sut, with: nil)
    }
    
    func test_delete_hasNoSideEffectsOnDeletionError_onNonEmptyCache() {
        let stub = NSManagedObjectContext.alwaysFailingSaveStub()
        let cache = makeCache()
        let sut = makeSUT()

        insert(cache: cache, to: sut)

        stub.startIntercepting()

        assert_delete_hasNoSideEffectsOnDeletionError(on: sut, with: cache)
    }
    
    func test_delete_removesAllObjects() throws {
        let store = makeSUT()

        insert(cache: makeCache(), to: store)

        deleteCache(from: store)

        let context = try NSPersistentContainer.load(
            name: CoreDataFeedStore.modelName,
            model: XCTUnwrap(CoreDataFeedStore.model),
            url: inMemoryStoreURL()
        ).viewContext

        let existingObjects = try context.allExistingObjects()

        XCTAssertEqual(existingObjects, [], "found orphaned objects in Core Data")
    }

    func test_storeSideEffects_runSerially() {
        let sut = makeSUT()
        
        assert_storeSideEffects_runSerially(on: sut)
    }
    
    func test_imageEntity_properties() throws {
        let entity = try XCTUnwrap(
            CoreDataFeedStore.model?.entitiesByName["ManagedFeedImage"]
        )

        entity.verify(attribute: "id", hasType: .UUIDAttributeType, isOptional: false)
        entity.verify(attribute: "imageDescription", hasType: .stringAttributeType, isOptional: true)
        entity.verify(attribute: "location", hasType: .stringAttributeType, isOptional: true)
        entity.verify(attribute: "url", hasType: .URIAttributeType, isOptional: false)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #file,
        line: UInt = #line
    ) -> CoreDataFeedStore {
        let sut = try! CoreDataFeedStore(storeURL: inMemoryStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func inMemoryStoreURL() -> URL {
        URL(fileURLWithPath: "/dev/null")
            .appendingPathComponent("\(type(of: self)).store")
    }
}
