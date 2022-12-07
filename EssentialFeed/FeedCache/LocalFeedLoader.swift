//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Joanda Febrian on 06/12/22.
//

import Foundation

private final class FeedCachePolicy {
    private static let calendar = Calendar(identifier: .gregorian)
    private static var maxCacheAgeInDays: Int { 7 }
    
    private init() {}
    
    static func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard let maxCacheAge = calendar.date(
            byAdding: .day,
            value: maxCacheAgeInDays,
            to: timestamp
        ) else {
            return false
        }
        
        return date < maxCacheAge
    }
}

public final class LocalFeedLoader: FeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public init(
        store: FeedStore,
        currentDate: @escaping () -> Date
    ) {
        self.store = store
        self.currentDate = currentDate
    }
    
    private func validate(_ timestamp: Date) -> Bool {
        FeedCachePolicy.validate(timestamp, against: currentDate())
    }
}

extension LocalFeedLoader {
    public typealias SaveResult = Error?
    
    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] result in
            guard let self else { return }
            
            if let cacheDeletionResult = result {
                completion(cacheDeletionResult)
            } else {
                self.cache(feed, with: completion)
            }
        }
    }
    
    private func cache(_ feed: [FeedImage], with completion: @escaping (SaveResult) -> Void) {
        store.insert(feed.map(\.localFeed), timestamp: currentDate()) { [weak self] result in
            guard self != nil else { return }
            completion(result)
        }
    }
}

extension LocalFeedLoader {
    public typealias LoadResult = LoadFeedResult
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self else { return }
            
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .found(localFeed, timestamp) where self.validate(timestamp):
                completion(.success(localFeed.map(\.feedImage)))
            case .found, .empty:
                completion(.success([]))
            }
        }
    }
}

extension LocalFeedLoader {
    public func validateCache() {
        store.retrieve { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .failure:
                self.store.deleteCachedFeed { _ in }
            case let .found(_, timestamp) where !self.validate(timestamp):
                self.store.deleteCachedFeed { _ in }
            case .found, .empty: break
            }
        }
    }
}

private extension FeedImage {
    var localFeed: LocalFeedImage {
        LocalFeedImage(
            id: id,
            description: description,
            location: location,
            url: url
        )
    }
}

private extension LocalFeedImage {
    var feedImage: FeedImage {
        FeedImage(
            id: id,
            description: description,
            location: location,
            url: url
        )
    }
}
