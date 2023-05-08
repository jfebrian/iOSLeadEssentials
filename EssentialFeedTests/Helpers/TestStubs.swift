//
//  XCTestCase+URL.swift
//  EssentialFeedTests
//
//  Created by Joanda Febrian on 07/12/22.
//

import XCTest

var anyURL: URL { URL(string: "http://any-url.com/")! }
var anyData: Data { Data("any data".utf8) }
var anyNSError: NSError { NSError(domain: "any error", code: 0) }
