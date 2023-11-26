//
//  UIButton+TestHelpers.swift
//  EssentialFeediOSTests
//
//  Created by Joanda Febrian on 28/01/23.
//

import UIKit

extension UIButton {
    func simulateTap() {
        simulate(event: .touchUpInside)
    }
}
