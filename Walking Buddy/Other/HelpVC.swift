//
//  HelpVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 16/02/2023.
//
//	Implements the help view controller

import UIKit

class HelpVC: UIViewController {
	
	//Scroll view showing the help page content
	@IBOutlet weak var scrollView: UIScrollView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	//When the my profile button is tapped
	@IBAction func myProfile(_ sender: Any) {
		AppDelegate.get().setDesiredTabIndex(3)
		showVC(identifier: "tabController")
	}
	
	// MARK: - Friends section
	
	@IBAction func friendsHeading(_ sender: Any) {
		scrollTo(yPos: 1079)
	}
	
	@IBAction func friends1(_ sender: Any) {
		scrollTo(yPos: 1124.5)
	}
	
	@IBAction func friends2(_ sender: Any) {
		scrollTo(yPos: 1212)
	}
	
	@IBAction func friends3(_ sender: Any) {
		scrollTo(yPos: 1321)
	}
	
	@IBAction func friends4(_ sender: Any) {
		scrollTo(yPos: 1460.5)
	}
	
	@IBAction func friends5(_ sender: Any) {
		scrollTo(yPos: 1543.5)
	}
	
	// MARK: - Photos section
	
	@IBAction func photosHeading(_ sender: Any) {
		scrollTo(yPos: 1780)
	}
	
	@IBAction func photos1(_ sender: Any) {
		scrollTo(yPos: 1825.5)
	}
	
	@IBAction func photos2(_ sender: Any) {
		scrollTo(yPos: 2113)
	}
	
	@IBAction func photos3(_ sender: Any) {
		scrollTo(yPos: 2248.5)
	}
	
	@IBAction func photos4(_ sender: Any) {
		scrollTo(yPos: 2387.5)
	}
	
	@IBAction func photos5(_ sender: Any) {
		scrollTo(yPos: 2597)
	}
	
	@IBAction func photos6(_ sender: Any) {
		scrollTo(yPos: 2809)
	}
	
	// MARK: - Chat section
	
	@IBAction func chatHeading(_ sender: Any) {
		scrollTo(yPos: 2970.5)
	}
	
	@IBAction func chat1(_ sender: Any) {
		scrollTo(yPos: 3017)
	}
	
	@IBAction func chat2(_ sender: Any) {
		scrollTo(yPos: 3176)
	}
	
	@IBAction func chat3(_ sender: Any) {
		scrollTo(yPos: 3341.5)
	}
	
	// MARK: - Challenges section
	
	@IBAction func challengesHeading(_ sender: Any) {
		scrollTo(yPos: 3528.5)
	}
	
	@IBAction func challenges1(_ sender: Any) {
		scrollTo(yPos: 3571.5)
	}
	
	@IBAction func challenges2(_ sender: Any) {
		scrollTo(yPos: 3810.5)
	}
	
	@IBAction func challenges3(_ sender: Any) {
		scrollTo(yPos: 3946.5)
	}
	
	@IBAction func challenges4(_ sender: Any) {
		scrollTo(yPos: 3995)
	}
	
	// MARK: - Achievements section
	
	@IBAction func achievementsHeading(_ sender: Any) {
		scrollTo(yPos: 3995)
	}
	
	@IBAction func achievements1(_ sender: Any) {
		scrollTo(yPos: 3995)
	}
	
	@IBAction func achievements2(_ sender: Any) {
		scrollTo(yPos: 3995)
	}
	
	// MARK: - Functions
	
	//Scrolls the page to a given y-axis position
	private func scrollTo(yPos: Double) {
		self.view.layoutIfNeeded()
		scrollView.setContentOffset(CGPoint(x: 0, y: yPos), animated: true)
	}
	
	//Shows view controller with given identifier
	private func showVC(identifier: String) {
		AppDelegate.get().filterNavigationStack(identifier)
		let vc = self.storyboard?.instantiateViewController(withIdentifier: identifier)
		vc?.modalPresentationStyle = .overFullScreen
		self.present(vc!, animated: true)
	}
}
