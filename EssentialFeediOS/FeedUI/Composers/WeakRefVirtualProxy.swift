//
//  WeakRefVirtualProxy.swift
//  EssentialFeediOS
//
//  Created by Joanda Febrian on 29/01/23.
//

import Foundation

final class WeakRefVirtualProxy<T: AnyObject> {
    weak var object: T?
    
    init(_ object: T) {
        self.object = object
    }
}
