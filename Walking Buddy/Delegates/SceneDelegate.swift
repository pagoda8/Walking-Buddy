//
//  SceneDelegate.swift
//  Walking Buddy
//
//  Created by Wojtek on 28/10/2022.
//
//	SceneDelegate class

import UIKit
import StreamChatUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: UIWindow?

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		// Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
		// If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
		// This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
		guard let _ = (scene as? UIWindowScene) else { return }
		
		chatAppearanceSetup()
	}

	func sceneDidDisconnect(_ scene: UIScene) {
		// Called as the scene is being released by the system.
		// This occurs shortly after the scene enters the background, or when its session is discarded.
		// Release any resources associated with this scene that can be re-created the next time the scene connects.
		// The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
	}

	func sceneDidBecomeActive(_ scene: UIScene) {
		// Called when the scene has moved from an inactive state to an active state.
		// Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
	}

	func sceneWillResignActive(_ scene: UIScene) {
		// Called when the scene will move from an active state to an inactive state.
		// This may occur due to temporary interruptions (ex. an incoming phone call).
	}

	func sceneWillEnterForeground(_ scene: UIScene) {
		// Called as the scene transitions from the background to the foreground.
		// Use this method to undo the changes made on entering the background.
	}

	func sceneDidEnterBackground(_ scene: UIScene) {
		// Called as the scene transitions from the foreground to the background.
		// Use this method to save data, release shared resources, and store enough scene-specific state information
		// to restore the scene back to its current state.

		// Save changes in the application's managed object context when the application transitions to the background.
		(UIApplication.shared.delegate as? AppDelegate)?.saveContext()
	}
	
	//Sets up the StreamChat appearance
	private func chatAppearanceSetup() {
		Components.default.channelVC = ChannelVC.self
		Components.default.channelContentView = ChannelListItem.self
		Components.default.threadVC = ThreadVC.self
		
		Appearance.default.colorPalette.text = .black
		Appearance.default.colorPalette.textInverted = .white
		Appearance.default.colorPalette.textLowEmphasis = .gray
		Appearance.default.colorPalette.staticColorText = .white
		Appearance.default.colorPalette.subtitleText = .gray
		
		Appearance.default.colorPalette.messageCellHighlightBackground = .lightGray
		//Appearance.default.colorPalette.jumpToUnreadButtonBackground
		//Appearance.default.colorPalette.pinnedMessageBackground
		//Appearance.default.colorPalette.hoverButtonShadow
		
		//Appearance.default.colorPalette.highlightedColorForColor
		//Appearance.default.colorPalette.disabledColorForColor
		//Appearance.default.colorPalette.unselectedColorForColor
		
		Appearance.default.colorPalette.background = UIColor.theme.background
		Appearance.default.colorPalette.background1 = .lightGray
		Appearance.default.colorPalette.background2 = .lightGray
		Appearance.default.colorPalette.background3 = .gray
		Appearance.default.colorPalette.background4 = .gray
		Appearance.default.colorPalette.background5 = .gray
		Appearance.default.colorPalette.background6 = UIColor.theme.blueTransparent
		Appearance.default.colorPalette.background7 = .lightGray
		Appearance.default.colorPalette.background8 = UIColor.theme.background
		
		Appearance.default.colorPalette.overlayBackground = .gray
		Appearance.default.colorPalette.popoverBackground = UIColor.theme.background
		Appearance.default.colorPalette.highlightedBackground = .lightGray
		Appearance.default.colorPalette.highlightedAccentBackground = UIColor.theme.blue
		Appearance.default.colorPalette.highlightedAccentBackground1 = UIColor.theme.blue
		
		Appearance.default.colorPalette.shadow = .gray
		Appearance.default.colorPalette.lightBorder = .white
		Appearance.default.colorPalette.border = .gray
		Appearance.default.colorPalette.border2 = .gray
		Appearance.default.colorPalette.border3 = .gray
		
		Appearance.default.colorPalette.accentPrimary = UIColor.theme.blue
		Appearance.default.colorPalette.alternativeActiveTint = UIColor.theme.blue
		Appearance.default.colorPalette.inactiveTint = .gray
		Appearance.default.colorPalette.alternativeInactiveTint = .gray
	}
}
