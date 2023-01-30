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
	}
}
