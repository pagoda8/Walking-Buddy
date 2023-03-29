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
		//print(scrollView.contentOffset)
		AppDelegate.get().setDesiredTabIndex(3)
		showVC(identifier: "tabController")
	}
	
	// MARK: - Friends section
	
	@IBAction func friendsHeading(_ sender: Any) {
		scrollTo(yPos: 653.5)
	}
	
	@IBAction func friends1(_ sender: Any) {
		scrollTo(yPos: 703)
	}
	
	@IBAction func friends2(_ sender: Any) {
		scrollTo(yPos: 787)
	}
	
	@IBAction func friends3(_ sender: Any) {
		scrollTo(yPos: 898.5)
	}
	
	@IBAction func friends4(_ sender: Any) {
		scrollTo(yPos: 1036.5)
	}
	
	@IBAction func friends5(_ sender: Any) {
		scrollTo(yPos: 1126.5)
	}
	
	// MARK: - Challenges section
	
	@IBAction func challengesHeading(_ sender: Any) {
		scrollTo(yPos: 1689)
	}
	
	@IBAction func challenges1(_ sender: Any) {
		scrollTo(yPos: 1736)
	}
	
	@IBAction func challenges2(_ sender: Any) {
		scrollTo(yPos: 1979)
	}
	
	@IBAction func challenges3(_ sender: Any) {
		scrollTo(yPos: 2109.5)
	}
	
	@IBAction func challenges4(_ sender: Any) {
		scrollTo(yPos: 2299)
	}
	
	// MARK: - Achievements section
	
	@IBAction func achievementsHeading(_ sender: Any) {
		
	}
	
	@IBAction func achievements1(_ sender: Any) {
		
	}
	
	@IBAction func achievements2(_ sender: Any) {
		
	}
	
	// MARK: - Functions
	
	//Scrolls the page to a given y-axis position
	private func scrollTo(yPos: Double) {
		self.view.layoutIfNeeded()
		scrollView.setContentOffset(CGPoint(x: 0, y: yPos), animated: true)
	}
	
	//Shows view controller with given identifier
	private func showVC(identifier: String) {
		let vc = self.storyboard?.instantiateViewController(withIdentifier: identifier)
		vc?.modalPresentationStyle = .overFullScreen
		self.present(vc!, animated: true)
	}
}
