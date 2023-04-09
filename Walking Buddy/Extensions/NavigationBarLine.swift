//
//  NavigationBarLine.swift
//  Walking Buddy
//
//  Created by Wojtek on 09/04/2023.
//
//	Enables adding a bottom line to a navigation bar

import Foundation
import UIKit

extension UINavigationController {
	
	func addBottomLine(color: UIColor, height: Double) {
		navigationBar.setValue(true, forKey: "hidesShadow")
	
		let lineView = UIView()
		lineView.backgroundColor = color
		navigationBar.addSubview(lineView)
	
		lineView.translatesAutoresizingMaskIntoConstraints = false
		lineView.widthAnchor.constraint(equalTo: navigationBar.widthAnchor).isActive = true
		lineView.heightAnchor.constraint(equalToConstant: height).isActive = true
		lineView.centerXAnchor.constraint(equalTo: navigationBar.centerXAnchor).isActive = true
		lineView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor).isActive = true
	}
}
