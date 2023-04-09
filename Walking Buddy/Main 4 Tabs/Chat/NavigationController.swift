//
//  NavigationController.swift
//  Walking Buddy
//
//  Created by Wojtek on 06/04/2023.
//
//	Implements a navigation controller responsible for the chat interface

import UIKit

class NavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
		self.navigationBar.barStyle = .default
		self.addBottomLine(color: .gray, height: 0.7)
		self.navigationBar.standardAppearance.backgroundEffect = nil
		self.navigationBar.standardAppearance.titleTextAttributes = [.foregroundColor: UIColor.black]
    }
	
	override func popViewController(animated: Bool) -> UIViewController? {
		let vc = super.popViewController(animated: false)
		return vc
	}
	
	override func pushViewController(_ viewController: UIViewController, animated: Bool) {
		super.pushViewController(viewController, animated: false)
	}
}
