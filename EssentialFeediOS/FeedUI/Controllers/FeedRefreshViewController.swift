//
//  FeedRefreshViewController.swift
//  EssentialFeediOS
//
//  Created by Joanda Febrian on 28/01/23.
//

import UIKit

protocol FeedRefreshViewControllerDelegate {
    func didRequestFeedRefresh()
}

final class FeedRefreshViewController: NSObject {
    private(set) lazy var view: UIRefreshControl = {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }()
    
    private let delegate: FeedRefreshViewControllerDelegate
    
    init(delegate: FeedRefreshViewControllerDelegate) {
        self.delegate = delegate
    }
    
    @objc func refresh() {
        delegate.didRequestFeedRefresh()
    }
}

extension FeedRefreshViewController: FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel) {
        if viewModel.isLoading {
            view.beginRefreshing()
        } else {
            view.endRefreshing()
        }
    }
}
