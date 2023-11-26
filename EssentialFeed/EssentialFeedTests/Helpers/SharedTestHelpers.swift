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

func makeItemsJSON(_ items: [[String: Any]]) -> Data {
    let json = ["items": items]
    return try! JSONSerialization.data(withJSONObject: json)
}

extension HTTPURLResponse {
    convenience init(statusCode: Int) {
        self.init(url: anyURL, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}
