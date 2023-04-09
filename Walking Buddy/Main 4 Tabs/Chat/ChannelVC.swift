//
//  ChannelVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 08/04/2023.
//
//	Custom ChatChannelVC responsible for showing a channel

import Foundation
import StreamChatUI

class ChannelVC: ChatChannelVC {
	
	override func setUpAppearance() {
		super.setUpAppearance()
		self.navigationItem.rightBarButtonItems = []
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		guard let superview = view.superview else {
			return
		}
		self.view.translatesAutoresizingMaskIntoConstraints = false
		self.view.topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
		self.view.bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
		self.view.leadingAnchor.constraint(equalTo: superview.leadingAnchor).isActive = true
		self.view.trailingAnchor.constraint(equalTo: superview.trailingAnchor).isActive = true
	}
}
