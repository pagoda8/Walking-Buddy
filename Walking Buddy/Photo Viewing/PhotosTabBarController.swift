//
//  PhotosTabBarController.swift
//  Walking Buddy
//
//  Created by Wojtek on 26/03/2023.
//
//	Implements the photos tab bar controller

import Foundation
import UIKit

class PhotosTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
		//Set tab to open
		self.selectedIndex = AppDelegate.get().getDesiredPhotosTabIndex()
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
