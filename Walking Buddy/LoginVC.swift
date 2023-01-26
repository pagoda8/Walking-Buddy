//
//  LoginVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 28/10/2022.
//
//	Implements the Login View Controller

import UIKit
import AuthenticationServices
import CloudKit

class LoginVC: UIViewController {

	//Button to sign in
	private let signInButton = ASAuthorizationAppleIDButton()
	
	//Error description when user closes the sign in prompt
	private let errorString = "The operation couldn’t be completed. (com.apple.AuthenticationServices.AuthorizationError error 1001.)"
	//Reference to db manager
	private let db = DBManager.shared
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.addSubview(signInButton)
		signInButton.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		//Button appearance
		signInButton.frame = CGRect(x: 0, y: 0, width: 300, height: 60)
		signInButton.center = CGPoint(x: view.center.x, y: view.center.y + 300)
	}
	
	//When sign in button is tapped
	@objc func signInTapped() {
		let provider = ASAuthorizationAppleIDProvider()
		let request = provider.createRequest()
		request.requestedScopes = [.fullName]
		
		let controller = ASAuthorizationController(authorizationRequests: [request])
		
		controller.delegate = self
		controller.presentationContextProvider = self
		controller.performRequests()
	}
	
	//Shows storyboard with given identifier
	private func showStoryboard(identifier: String) {
		let vc = self.storyboard?.instantiateViewController(withIdentifier: identifier)
		vc?.modalPresentationStyle = .overFullScreen
		self.present(vc!, animated: true)
	}
	
	//Vibrates phone with given style
	private func vibrate(style: UIImpactFeedbackGenerator.FeedbackStyle) {
		let generator = UIImpactFeedbackGenerator(style: style)
		generator.impactOccurred()
	}
	
	//Shows alert with given title and message
	private func showAlert(title: String, message: String) {
		vibrate(style: .light)
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default))
		self.present(alert, animated: true)
	}

}

extension LoginVC: ASAuthorizationControllerDelegate {
	//Authorization error
	func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
		
		let profile = CKRecord(recordType: "Profiles")
		profile["id"] = "123"
		profile["firstName"] = "Wojtek"
		profile["lastName"] = "Lag"
		
		DBManager.shared.db.publicCloudDatabase.save(profile) { returnedRecord, returnedError in
			print("Record:\n")
			print(returnedRecord.debugDescription)
			print("Error:\n")
			print(returnedError?.localizedDescription ?? "")
		}
		
		//If an actual error occured
		if (error.localizedDescription != errorString) {
			showAlert(title: "Error while signing in", message: "Try again later")
		}
	}
	
	//Authorization successful
	func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
		
		switch authorization.credential {
		case let credentials as ASAuthorizationAppleIDCredential:
			//Get user id
			let id = credentials.user
			
			
			
			let newUser = true
			
			if newUser {
				let firstName = credentials.fullName?.givenName
				let lastName = credentials.fullName?.familyName
				
				let profile = CKRecord(recordType: "Profiles")
				profile["id"] = id
				profile["firstName"] = firstName
				profile["lastName"] = lastName
				
				DBManager.shared.db.publicCloudDatabase.save(profile) { returnedRecord, returnedError in
					
				}
			}
			else {
				AppDelegate.get().setCurrentUser(id)
				//go to main screen
			}
			
			
			//If it's a new user then store data in db, open profile creation screen
			break
		default:
			break
		}
	}
}

extension LoginVC: ASAuthorizationControllerPresentationContextProviding {
	func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
		return view.window!
	}
}

