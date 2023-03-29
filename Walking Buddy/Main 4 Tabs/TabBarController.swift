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
		tabBarSetup()
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		tabBarSetup()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
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
