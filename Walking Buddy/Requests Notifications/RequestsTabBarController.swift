//
//  RequestsTabBarController.swift
//  Walking Buddy
//
//  Created by Wojtek on 06/02/2023.
//

import Foundation
import UIKit

class RequestsTabBarController: UITabBarController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		//Set tab to open
		self.selectedIndex = AppDelegate.get().getDesiredRequestsTabIndex()
	}
}
