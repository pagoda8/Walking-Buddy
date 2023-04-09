//
//  TabBarController.swift
//  Walking Buddy
//
//  Created by Wojtek on 30/01/2023.
//
//	Implements the Tab Bar Controller

import Foundation
import UIKit

class TabBarController: UITabBarController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		//Set tab to open
		self.selectedIndex = AppDelegate.get().getDesiredTabIndex()
		AppDelegate.get().clearNavigationStack()
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		tabBarSetup()
	}
	
	private func tabBarSetup() {
		//Round corners
		self.tabBar.layer.masksToBounds = true
		self.tabBar.layer.cornerRadius = 8
		self.tabBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
	}
}
