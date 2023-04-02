//
//  RequestsTabBarController.swift
//  Walking Buddy
//
//  Created by Wojtek on 06/02/2023.
//
//	Implements the requests tab bar controller

import Foundation
import UIKit

class RequestsTabBarController: UITabBarController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		//Set tab to open
		self.selectedIndex = AppDelegate.get().getDesiredRequestsTabIndex()
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		tabBarSetup()
	}
	
	private func tabBarSetup() {
		//Round corners
		self.tabBar.layer.masksToBounds = true
		self.tabBar.layer.cornerRadius = 8
		self.tabBar.layer.maskedCorners = [.layerMinXMinYCorner,.layerMaxXMinYCorner]
		
		//Shadow
		self.tabBar.layer.shadowColor = UIColor.darkGray.cgColor
		self.tabBar.layer.shadowOffset = CGSize(width: 0.0, height: -1.0)
		self.tabBar.layer.shadowRadius = 2
		self.tabBar.layer.shadowOpacity = 0.5
	}
}
