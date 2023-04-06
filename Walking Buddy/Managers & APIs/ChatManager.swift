//
//  ChatManager.swift
//  Walking Buddy
//
//  Created by Wojtek on 05/04/2023.
//
//	Manages interactions with StreamChat
//	API used: https://getstream.io

import Foundation
import StreamChat
import StreamChatUI

final class ChatManager {
	
	//Reference for other classes
	static let shared = ChatManager()
	
	//The chat client
	private var client: ChatClient!
	
	// MARK: - Functions
	
	//Set up chat client
	func setup() {
		self.client = ChatClient(config: .init(apiKey: .init("65av7ppybsgk")))
	}
	
	// MARK: - Authentication
	
	//Sign in user to StreamChat
	func signIn(with username: String, and name: String, and imageUrl: URL?, completion: @escaping (Bool) -> Void) {
		guard !username.isEmpty, !name.isEmpty else {
			completion(false)
			return
		}
		
		client.connectUser(userInfo: .init(id: username, name: name, imageURL: imageUrl), token: .development(userId: username)) { error in
			completion(error == nil)
		}
	}
	
	//Sign out user from StreamChat
	func signOut() {
		client.disconnect {}
		client.logout {}
	}
	
	// MARK: - Properties
	
	//Returns a bool whether the user is signed in to StreamChat
	var isSignedIn: Bool {
		return client.currentUserId != nil
	}
	
	//Returns the username of the signed in user
	var currentUser: String? {
		return client.currentUserId
	}
}
