//
//  ChatVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 30/01/2023.
//
//	Implements the Chat Tab View Controller
//	Signs in the user to StreamChat and embeds a chat navigation controller

import UIKit
import CloudKit

class ChatVC: UIViewController {
	
	//Reference to db manager
	private let db = DBManager.shared
	
	//Used to show that chat is loading
	private let activityIndicator = UIActivityIndicatorView(style: .medium)
	
	//View that embeds a navigation controller with the chat interface
	@IBOutlet weak var chatView: UIView!
	
	//Label shown if user could not get signed in to chat
	@IBOutlet weak var errorLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
		activityIndicatorSetup()
		
		if ChatManager.shared.isSignedIn {
			self.embedChat()
		}
		else {
			signInToChat() { [weak self] (success) in
				if success {
					DispatchQueue.main.async {
						self?.embedChat()
					}
				}
				else {
					DispatchQueue.main.async {
						self?.errorLabel.isHidden = false
					}
				}
			}
		}
    }
	
	// MARK: - Functions
	
	//Embeds a navigation controller inside the chatView
	private func embedChat() {
		guard let channelListVC = ChatManager.shared.createChannelList() else {
			self.errorLabel.isHidden = false
			return
		}
		(channelListVC as? ChannelListVC)?.setViewFrame(frame: chatView.bounds)
		
		let navController = NavigationController(rootViewController: channelListVC)
		navController.willMove(toParent: self)
		self.addChild(navController)
		self.chatView.addSubview(navController.view)
		
		navController.view.frame = chatView.bounds
		navController.view.centerXAnchor.constraint(equalTo: chatView.centerXAnchor).isActive = true
		navController.view.centerYAnchor.constraint(equalTo: chatView.centerYAnchor).isActive = true
		
		navController.didMove(toParent: self)
	}
	
	//Signs in the user to chat api
	private func signInToChat(completion: @escaping (Bool) -> Void) {
		activityIndicator.startAnimating()
		getUserInfo() { (userID, fullName) in
			let userChatID = userID.replacingOccurrences(of: ".", with: "-")
			ChatManager.shared.signIn(with: userChatID, and: fullName) { [weak self] (success) in
				DispatchQueue.main.async {
					self?.activityIndicator.stopAnimating()
				}
				completion(success)
			}
		}
	}
	
	//Returns the ID and full name of the user
	private func getUserInfo(completion: @escaping (String, String) -> Void) {
		let userID = AppDelegate.get().getCurrentUser()
		let predicate = NSPredicate(format: "id == %@", userID)
		let query = CKQuery(recordType: "Profiles", predicate: predicate)
		
		db.getRecords(query: query) { returnedRecords in
			let profileRecord = returnedRecords[0]
			let firstName = profileRecord["firstName"] as! String
			let lastName = profileRecord["lastName"] as! String
			completion(userID, firstName + " " + lastName)
		}
	}
	
	//Sets up the activity indicator
	private func activityIndicatorSetup() {
		view.addSubview(activityIndicator)
		activityIndicator.translatesAutoresizingMaskIntoConstraints = false
		activityIndicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
		activityIndicator.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -40).isActive = true
		activityIndicator.backgroundColor = UIColor(white: 0, alpha: 0)
		activityIndicator.color = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
		activityIndicator.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
	}
}
