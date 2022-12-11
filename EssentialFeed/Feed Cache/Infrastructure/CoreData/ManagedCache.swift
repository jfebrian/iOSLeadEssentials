//
//  ManagedCache.swift
//  EssentialFeed
//
//  Created by Joanda Febrian on 11/12/22.
//

import CoreData

@objc(ManagedCache)
class ManagedCache: NSManagedObject {
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
