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
	
	private func attributedText() -> NSAttributedString {
		let heading1 = "1 Friends\n"
		let subheading11 = "\t1.1 Viewing friends\n"
		let text11 = "\t\tTo view your friends, go to the Profile tab and tap the My friends button.\n"
		let subheading12 = "\t1.2 Adding friends\n"
		let text12 = "\t\tTo add a friend, go to your friends list and tap the plus button. Enter the person's username and tap Go to profile"
		
		
		let heading2 = "2 Walks\n\t"
		let text2 = "...\n\n"
		
		let heading3 = "3 Photos\n\t"
		let text3 = "...\n\n"
		
		let heading4 = "4 Challenges\n\t"
		let text4 = "...\n\n"
		
		let heading5 = "5 Achievements\n\t"
		let text5 = "...\n\n"
		
		let heading6 = "6 Chat\n\t"
		let text6 = "...\n\n"
		
		let string = heading1 + text11 + heading2 + text2 + heading3 + text3 + heading4 + text4 + heading5 + text5 + heading6 + text6 as NSString
		let attributedString = NSMutableAttributedString(string: string as String, attributes: [NSAttributedString.Key.font: UIFont(name: "Poppins-Regular", size: 18)!])
		
		let headingAttribute = [NSAttributedString.Key.font: UIFont(name: "Poppins-SemiBold", size: 22)]
		let subheadingAttribute = [NSAttributedString.Key.font: UIFont(name: "Poppins-SemiBold", size: 18)]
		
		attributedString.addAttributes(headingAttribute as [NSAttributedString.Key : Any], range: string.range(of: "1 Friends"))
		attributedString.addAttributes(headingAttribute as [NSAttributedString.Key : Any], range: string.range(of: "2 Walks"))
		attributedString.addAttributes(headingAttribute as [NSAttributedString.Key : Any], range: string.range(of: "3 Photos"))
		attributedString.addAttributes(headingAttribute as [NSAttributedString.Key : Any], range: string.range(of: "4 Challenges"))
		attributedString.addAttributes(headingAttribute as [NSAttributedString.Key : Any], range: string.range(of: "5 Achievements"))
		attributedString.addAttributes(headingAttribute as [NSAttributedString.Key : Any], range: string.range(of: "6 Chat"))
		
		return attributedString
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
