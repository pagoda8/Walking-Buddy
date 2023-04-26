//
//  ThreadVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 09/04/2023.
//
//	Custom ChatThreadVC responsible for showing a thread

import Foundation
import StreamChatUI

class ThreadVC: ChatThreadVC {
	
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
