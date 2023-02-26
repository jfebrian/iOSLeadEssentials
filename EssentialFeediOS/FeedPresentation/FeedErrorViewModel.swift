//
//  FeedErrorViewModel.swift
//  EssentialFeediOS
//
//  Created by Joanda Febrian on 26/02/23.
//

import Foundation

struct FeedErrorViewModel {
    let message: String?
    
    static var noError: FeedErrorViewModel {
        FeedErrorViewModel(message: nil)
    }

    static func error(message: String) -> FeedErrorViewModel {
        FeedErrorViewModel(message: message)
    }
}
