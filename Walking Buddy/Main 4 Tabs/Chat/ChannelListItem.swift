//
//  ChannelListItem.swift
//  Walking Buddy
//
//  Created by Wojtek on 08/04/2023.
//
//	Custom ChatChannelListItemView responsible for showing a channel item in the channel list

import Foundation
import UIKit
import StreamChatUI

class ChannelListItem: ChatChannelListItemView {
	
	//View that indicates unread messages
	private lazy var blueDot: UIView = {
		let blueDotView = UIView()
		blueDotView.backgroundColor = UIColor.theme.blue
		blueDotView.layer.masksToBounds = true
		blueDotView.layer.cornerRadius = 5
		blueDotView.clipsToBounds = true
		return blueDotView
	}()
	
	//Inset from right edge
	private lazy var space: UIView = {
		let spaceView = UIView()
		spaceView.alpha = 0
		spaceView.layer.masksToBounds = true
		spaceView.clipsToBounds = true
		return spaceView
	}()
	
	override func setUpAppearance() {
		super.setUpAppearance()
		titleLabel.textColor = .black
	}
	
	override func setUpLayout() {
		super.setUpLayout()
		
		blueDot.widthAnchor.constraint(equalTo: blueDot.heightAnchor).isActive = true
		blueDot.widthAnchor.constraint(equalToConstant: 10).isActive = true
		
		space.widthAnchor.constraint(equalTo: space.heightAnchor).isActive = true
		space.widthAnchor.constraint(equalToConstant: 10).isActive = true
		
		topContainer.removeArrangedSubview(unreadCountView)
		mainContainer.insertArrangedSubview(blueDot, at: 0)
		mainContainer.insertArrangedSubview(space, at: 3)
	}
	
	override func updateContent() {
		super.updateContent()
		blueDot.alpha = unreadCountView.content == .noUnread ? 0 : 1
	}
}
