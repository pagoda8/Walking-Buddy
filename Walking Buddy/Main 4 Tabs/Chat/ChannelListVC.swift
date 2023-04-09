//
//  ChannelListVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 06/04/2023.
//
//	Custom ChatChannelListVC responsible for showing a list of channels

import Foundation
import StreamChatUI

class ChannelListVC: ChatChannelListVC {
	
	override func setUpAppearance() {
		super.setUpAppearance()
		self.title = "My chats"
		self.navigationItem.leftBarButtonItems = []
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
