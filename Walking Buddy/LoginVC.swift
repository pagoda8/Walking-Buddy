//
//  LoginVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 28/10/2022.
//

import UIKit
import AuthenticationServices

class LoginVC: UIViewController {

	private let signInButton = ASAuthorizationAppleIDButton()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.addSubview(signInButton)
		signInButton.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		signInButton.frame = CGRect(x: 0, y: 0, width: 300, height: 60)
		signInButton.center = CGPoint(x: view.center.x, y: view.center.y + 300)
	}
	
	@objc func signInTapped() {
		let provider = ASAuthorizationAppleIDProvider()
		let request = provider.createRequest()
		request.requestedScopes = [.fullName, .email]
		
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
	func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {}
	
	func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
		
		switch authorization.credential {
		case let credentials as ASAuthorizationAppleIDCredential:
			//Generate user id, new user bool, logged in user id var (in app delegate)
			let firstName = credentials.fullName?.givenName
			let lastName = credentials.fullName?.familyName
			let email = credentials.email
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

