//
//  FeedCacheTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Joanda Febrian on 07/12/22.
//

import XCTest
import EssentialFeed

extension XCTestCase {
    func uniqueImage() -> FeedImage {
        FeedImage(id: UUID(), url: anyURL)
    }

    func uniqueImageFeed() -> (models: [FeedImage], locals: [LocalFeedImage]) {
        let models = [uniqueImage(), uniqueImage()]
        let locals = models.map {
            LocalFeedImage(
                id: $0.id,
                description: $0.description,
                location: $0.location,
                url: $0.url
            )
        }
        return (models, locals)
    }
}

extension Date {
    func adding(days: Int) -> Date {
        Calendar(identifier: .gregorian)
            .date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: Int) -> Date {
        Calendar(identifier: .gregorian)
            .date(byAdding: .second, value: seconds, to: self)!
    }
}
