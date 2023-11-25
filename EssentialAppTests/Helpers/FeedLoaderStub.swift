// Created by Joanda Febrian. All rights reserved.

import EssentialFeed

class FeedLoaderStub: FeedLoader {
    private let result: LoadFeedResult

    init(result: LoadFeedResult) {
        self.result = result
    }

    func load(completion: @escaping (LoadFeedResult) -> Void) {
        completion(result)
    }
}
