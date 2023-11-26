//
//  UITableView+DequeueCell.swift
//  EssentialFeediOS
//
//  Created by Joanda Febrian on 22/02/23.
//

import UIKit

extension UITableView {
    func dequeueReusableCell<T: UITableViewCell>() -> T {
        let identifier = String(describing: T.self)
        return dequeueReusableCell(withIdentifier: identifier) as! T
    }
}
