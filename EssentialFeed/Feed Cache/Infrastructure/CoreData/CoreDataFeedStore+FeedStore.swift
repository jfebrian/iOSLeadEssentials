//
//  CoreDataFeedStore+FeedStore.swift
//  EssentialFeed
//
//  Created by Joanda Febrian on 08/05/23.
//

import CoreData

extension CoreDataFeedStore: FeedStore {
    public func retrieve(completion: @escaping RetrievalCompletion) {
        perform { context in
            completion(Result(catching: {
                try ManagedCache.find(in: context).map {
                    CachedFeed(feed: $0.localFeed, timestamp: $0.timestamp)
                }
            }))
        }
    }
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        perform { context in
            completion(Result(catching: {
                try ManagedCache.insert(feed: feed, timestamp: timestamp, to: context)
            }))
        }
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        perform { context in
            completion(Result(catching: {
                try ManagedCache.delete(in: context)
            }))
        }
    }
}
