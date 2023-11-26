//
//  XCTestCase+AssertEqualNSError.swift
//  EssentialFeedTests
//
//  Created by Joanda Febrian on 07/12/22.
//

import XCTest

func assertNSErrorEqual(
    _ receivedError: NSError,
    _ expectedError: NSError,
    file: StaticString = #file,
    line: UInt = #line
) {
    XCTAssertEqual(
        receivedError.domain, expectedError.domain,
        "Expected error with domain \(expectedError.domain), got \(receivedError.domain)",
        file: file,
        line: line
    )
    
    XCTAssertEqual(
        receivedError.code, expectedError.code,
        "Expected error with code \(expectedError.code), got \(receivedError.code)",
        file: file,
        line: line
    )
}
