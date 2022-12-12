//
//  XCTestCase+FailableDeleteFeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Joanda Febrian on 11/12/22.
//

import XCTest
import EssentialFeed

extension FailableDeleteFeedStoreSpecs where Self: XCTestCase {
    func assert_delete_deliversErrorOnDeletionError(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNotNil(deletionError, "Expected cache deletion to fail with error", file: file, line: line)
    }
    
    func assert_delete_hasNoSideEffectsOnDeletionError(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        deleteCache(from: sut)
        
        expect(sut, toRetrieve: .success(.none), file: file, line: line)
    }
}
