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

extension LocalFeedLoader: FeedCache {
    public typealias SaveResult = FeedCache.Result
    
    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] deletionResult in
            guard let self else { return }
            
            switch deletionResult {
            case let .failure(error):
                completion(.failure(error))
            case .success:
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
    public typealias LoadResult = Result<[FeedImage], Error>

    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self else { return }
            
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(.some(cache)) where self.validate(cache.timestamp):
                completion(.success(cache.feed.map(\.feedImage)))
            case .success:
                completion(.success([]))
            }
        }
    }
}

extension LocalFeedLoader {
    public typealias ValidationResult = Result<Void, Error>

    public func validateCache(completion: @escaping (ValidationResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .failure:
                self.store.deleteCachedFeed(completion: completion)
            case let .success(.some(cache)) where !self.validate(cache.timestamp):
                self.store.deleteCachedFeed(completion: completion)
            case .success:
                completion(.success(()))
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
