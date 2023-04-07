//
//  NavigationController.swift
//  Walking Buddy
//
//  Created by Wojtek on 06/04/2023.
//
//	Implements a chat navigation controller responsible for the chat interface

import UIKit

class NavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
		//Set title colour
		self.navigationBar.barStyle = .default
		self.navigationBar.standardAppearance.titleTextAttributes = [.foregroundColor: UIColor.black]
    }
}
