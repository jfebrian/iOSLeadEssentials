//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Joanda Febrian on 06/12/22.
//

import Foundation

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    private let calendar = Calendar(identifier: .gregorian)
    
    public typealias SaveResult = Error?
    public typealias LoadResult = LoadFeedResult
    
    public init(
        store: FeedStore,
        currentDate: @escaping () -> Date
    ) {
        self.store = store
        self.currentDate = currentDate
    }

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
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self else { return }
            
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .found(localFeed, timestamp) where self.validate(timestamp):
                completion(.success(localFeed.map(\.feedImage)))
            case .found:
                self.store.deleteCachedFeed { _ in }
                completion(.success([]))
            case .empty:
                completion(.success([]))
            }
        }
    }
    
    public func validateCache() {
        store.retrieve { _ in }
        store.deleteCachedFeed { _ in }
    }
    
    private func cache(_ feed: [FeedImage], with completion: @escaping (SaveResult) -> Void) {
        store.insert(feed.map(\.localFeed), timestamp: currentDate()) { [weak self] result in
            guard self != nil else { return }
            completion(result)
        }
    }
    
    private var maxCacheAgeInDays: Int { 7 }
    
    private func validate(_ timestamp: Date) -> Bool {
        guard let maxCacheAge = calendar.date(
            byAdding: .day,
            value: maxCacheAgeInDays,
            to: timestamp
        ) else {
            return false
        }
        
        return currentDate() < maxCacheAge
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
