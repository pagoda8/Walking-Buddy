//
//  HelpVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 16/02/2023.
//

import UIKit

class HelpVC: UIViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	@IBAction func myProfile(_ sender: Any) {
		AppDelegate.get().setDesiredTabIndex(4)
		showVC(identifier: "tabController")
	}
	
	//Shows view controller with given identifier
	private func showVC(identifier: String) {
		let vc = self.storyboard?.instantiateViewController(withIdentifier: identifier)
		vc?.modalPresentationStyle = .overFullScreen
		self.present(vc!, animated: true)
	}

}
