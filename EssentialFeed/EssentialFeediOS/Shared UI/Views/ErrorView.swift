//
//  ErrorView.swift
//  EssentialFeediOS
//
//  Created by Joanda Febrian on 26/02/23.
//

import UIKit

public final class ErrorView: UIButton {
    public var message: String? {
        get { isVisible ? title(for: .normal) : nil }
        set { setMessageAnimated(newValue) }
    }

    public var onHide: (() -> Void)?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func configure() {
        backgroundColor = .errorBackgroundColor

        addTarget(self, action: #selector(hideMessageAnimated), for: .touchUpInside)
        configureLabel()
        hideMessage()
    }

    private func configureLabel() {
        titleLabel?.textColor = .white
        titleLabel?.textAlignment = .center
        titleLabel?.numberOfLines = 0
        titleLabel?.font = .systemFont(ofSize: 17)
    }

    private var isVisible: Bool { alpha > 0 }

    private func setMessageAnimated(_ message: String?) {
        if let message {
            showAnimated(message)
        } else {
            hideMessageAnimated()
        }
    }

    private func showAnimated(_ message: String) {
        setTitle(message, for: .normal)
        setEdgeInset(top: -2.5, leading: 0, bottom: -2.5, trailing: 0)
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
        }
    }

    @objc private func hideMessageAnimated() {
        UIView.animate(
            withDuration: 0.25,
            animations: { self.alpha = 0 },
            completion: { completed in
                if completed { self.hideMessage() }
            }
        )
    }

    private func hideMessage() {
        setTitle(nil, for: .normal)
        alpha = 0
        setEdgeInset(top: -2.5, leading: 0, bottom: -2.5, trailing: 0)
        onHide?()
    }
    
    private func setEdgeInset(top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat) {
        guard var configuration else { return }

        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: top,
            leading: leading,
            bottom: bottom,
            trailing: trailing
        )
    }
}

extension UIColor {
    static var errorBackgroundColor: UIColor {
        UIColor(red: 0.99951404330000004, green: 0.41759261489999999, blue: 0.4154433012, alpha: 1)
    }
}
