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
import UIKit

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
	func signIn(with userID: String, and name: String, completion: @escaping (Bool) -> Void) {
		guard !userID.isEmpty, !name.isEmpty else {
			completion(false)
			return
		}
		
		let tokenProvider: TokenProvider = { completion in
			completion(.success(Token.development(userId: userID)))
		}
		let imageUrl = URL(string: "https://www.pngmart.com/files/22/User-Avatar-Profile-Transparent-Isolated-PNG.png")
		
		client.connectUser(userInfo: .init(id: userID, name: name, imageURL: imageUrl), tokenProvider: tokenProvider) { error in
			completion(error == nil)
		}
	}
	
	//Sign out user from StreamChat
	func signOut() {
		client.disconnect {}
		client.logout {}
	}
	
	// MARK: - Properties
	
	//Returns a bool whether the app user is signed in to StreamChat
	var isSignedIn: Bool {
		let currentAppUser = AppDelegate.get().getCurrentUser()
		guard let currentChatUser = client.currentUserId?.replacingOccurrences(of: "-", with: ".") else {
			return false
		}
		return currentAppUser == currentChatUser
	}
	
	//Returns the (StreamChat) user ID of the signed in user
	var currentUserChatID: String? {
		return client.currentUserId
	}
	
	// MARK: - Channels
	
	//Returns a view controller showing the user's channel list
	public func createChannelList() -> UIViewController? {
		guard let userID = currentUserChatID else {
			return nil
		}
		let channelList = client.channelListController(query: .init(filter: .containMembers(userIds: [userID])))
		let vc = ChannelListVC()
		vc.content = channelList
		channelList.synchronize()
		return vc
	}
}
