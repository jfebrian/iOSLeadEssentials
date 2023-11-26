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

extension Date {
    func adding(days: Int) -> Date {
        Calendar(identifier: .gregorian)
            .date(byAdding: .day, value: days, to: self)!
    }

    func adding(minutes: Int) -> Date {
        Calendar(identifier: .gregorian)
            .date(byAdding: .minute, value: minutes, to: self)!
    }

    func adding(seconds: Int) -> Date {
        Calendar(identifier: .gregorian)
            .date(byAdding: .second, value: seconds, to: self)!
    }
}
