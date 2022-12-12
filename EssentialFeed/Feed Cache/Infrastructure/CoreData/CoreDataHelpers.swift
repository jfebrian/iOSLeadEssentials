//
//  CoreDataHelpers.swift
//  EssentialFeed
//
//  Created by Joanda Febrian on 11/12/22.
//

import CoreData

extension NSPersistentContainer {
    enum LoadingError: Swift.Error {
        case modelNotFound
        case failedToLoadPersistentStores(Swift.Error)
    }
    
    static func load(
        name: String,
        model: NSManagedObjectModel,
        url: URL
    ) throws -> NSPersistentContainer {
        let description = NSPersistentStoreDescription(url: url)
        let container = NSPersistentContainer(name: name, managedObjectModel: model)
        container.persistentStoreDescriptions = [description]

        var loadError: Swift.Error?
        container.loadPersistentStores { loadError = $1 }
        try loadError.map { throw $0 }

        return container
    }
}

private extension NSManagedObjectModel {
    static func with(name: String, in bundle: Bundle) -> NSManagedObjectModel? {
        return bundle
            .url(forResource: name, withExtension: "momd")
            .flatMap(NSManagedObjectModel.init(contentsOf:))
    }
}

extension NSManagedObjectModel {
    convenience init?(name: String, in bundle: Bundle) {
        guard let momd = bundle.url(forResource: name, withExtension: "momd") else {
            return nil
        }
        self.init(contentsOf: momd)
    }
}
