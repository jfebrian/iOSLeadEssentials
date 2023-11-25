// Created by Joanda Febrian. All rights reserved.

import Foundation

func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 0)
}

func anyURL() -> URL {
    return URL(string: "any-url.com")!
}

func anyData() -> Data {
    return Data("any data".utf8)
}
