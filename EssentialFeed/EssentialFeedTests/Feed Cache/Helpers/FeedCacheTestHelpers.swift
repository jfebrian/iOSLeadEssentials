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
    func nonExpiredCacheDate() -> Date {
        cacheExpirationDate().adding(seconds: 1)
    }
    
    func expiredCacheDate() -> Date {
        cacheExpirationDate().adding(seconds: -1)
    }
    
    func cacheExpirationDate() -> Date {
        adding(days: -feedCacheMaxAgeInDays)
    }
    
    private var feedCacheMaxAgeInDays: Int { 7 }
}
