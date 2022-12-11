//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by Joanda Febrian on 11/12/22.
//

import CoreData

public final class CoreDataFeedStore: FeedStore {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    public init(storeURL: URL, bundle: Bundle = .main) throws {
        container = try NSPersistentContainer.load(modelName: "FeedStore", url: storeURL, in: bundle)
        context = container.newBackgroundContext()
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        perform { context in
            do {
                if let cache = try ManagedCache.find(in: context) {
                    completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
                } else {
                    completion(.empty)
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        perform { context in
            do {
                try ManagedCache.insert(feed: feed, timestamp: timestamp, to: context)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        perform { context in
            do {
                try ManagedCache.delete(in: context)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    private func perform(_ action: @escaping (NSManagedObjectContext) -> Void) {
        let context = self.context
        context.perform { action(context) }
    }
}

@objc(ManagedCache)
private class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var feed: NSOrderedSet
    
    var localFeed: [LocalFeedImage] {
        feed.compactMap { $0 as? ManagedFeedImage }
            .map(\.localFeedImage)
    }
    
    static func find(in context: NSManagedObjectContext) throws -> ManagedCache? {
        let request = NSFetchRequest<ManagedCache>(entityName: ManagedCache.entity().name!)
        request.returnsObjectsAsFaults = false
        return try context.fetch(request).first
    }
    
    static func delete(in context: NSManagedObjectContext) throws {
        try find(in: context).map(context.delete(_:)).map(context.save)
    }
    
    static func insert(
        feed: [LocalFeedImage],
        timestamp: Date,
        to context: NSManagedObjectContext
    ) throws {
        let managedCache = try ManagedCache.newUniqueInstance(in: context)
        managedCache.timestamp = timestamp
        managedCache.feed = NSOrderedSet(array: feed.manageFeed(in: context))
        
        try context.save()
    }
    
    static private func newUniqueInstance(in context: NSManagedObjectContext) throws -> ManagedCache {
        try find(in: context).map(context.delete(_:))
        return ManagedCache(context: context)
    }
}

@objc(ManagedFeedImage)
private class ManagedFeedImage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL
    @NSManaged var cache: ManagedCache
    
    var localFeedImage: LocalFeedImage {
        LocalFeedImage(
            id: id,
            description: imageDescription,
            location: location,
            url: url
        )
    }
}

private extension Array where Element == LocalFeedImage {
    func manageFeed(in context: NSManagedObjectContext) -> [ManagedFeedImage] {
        map { $0.managedFeedImage(in: context) }
    }
}

private extension LocalFeedImage {
    func managedFeedImage(in context: NSManagedObjectContext) -> ManagedFeedImage {
        let managed = ManagedFeedImage(context: context)
        managed.id = id
        managed.imageDescription = description
        managed.location = location
        managed.url = url
        return managed
    }
}
