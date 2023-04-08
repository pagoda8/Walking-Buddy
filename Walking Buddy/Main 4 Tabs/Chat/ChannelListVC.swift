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
	
	//The view frame of the channel list
	private var viewFrame: CGRect = CGRect()
	
	override func setUpAppearance() {
		super.setUpAppearance()
		title = "My chats"
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		view.frame = viewFrame
	}
	
	//Sets the view frame of the channel list
	public func setViewFrame(frame: CGRect) {
		self.viewFrame = frame
		view.layoutIfNeeded()
	}
}
