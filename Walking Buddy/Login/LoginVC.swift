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
	
	//Reference to db manager
	private let db = DBManager.shared
	
	//Error description when user closes the sign in prompt
	private let errorString = "The operation couldn’t be completed. (com.apple.AuthenticationServices.AuthorizationError error 1001.)"
	
	@IBOutlet weak var welcomeLogo: UIImageView! //Shows welcome logo
	@IBOutlet weak var launchLogo: UIImageView! //Shows launch logo
	
	// MARK: - View functions
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let savedUserID = UserDefaults.standard.object(forKey: "userID") as? String
		if savedUserID == nil {
			welcomeLogo.isHidden = false
			launchLogo.isHidden = true
			
			view.addSubview(signInButton)
			signInButton.addTarget(self, action: #selector(signIn), for: .touchUpInside)
			
			//Show sign in prompt when user opens app
			let isFirstLogin = AppDelegate.get().getFirstLoginBool()
			if isFirstLogin {
				signIn()
				AppDelegate.get().setFirstLoginBool(false)
			}
		}
		else {
			//Check if user has set up their profile
			cleanProfile(id: savedUserID!) { [weak self] clean in
				if clean {
					DispatchQueue.main.async {
						AppDelegate.get().setCurrentUser(savedUserID!)
						self?.showVC(identifier: "accountCreation")
					}
				}
				else {
					DispatchQueue.main.async {
						AppDelegate.get().setCurrentUser(savedUserID!)
						AppDelegate.get().setDesiredTabIndex(1)
						self?.showVC(identifier: "tabController")
					}
				}
			}
		}
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		//Sign in button appearance
		signInButton.frame = CGRect(x: 0, y: 0, width: 300, height: 60)
		signInButton.center = CGPoint(x: view.center.x, y: view.center.y + 300)
		signInButton.layer.masksToBounds = false
		signInButton.layer.shadowRadius = 1
		signInButton.layer.shadowOpacity = 0.5
		signInButton.layer.shadowOffset = CGSize(width: 0, height: 1)
		signInButton.layer.shadowColor = UIColor(named: "darkGray")?.cgColor
	}
	
	// MARK: - Functions
	
	//Shows sign in prompt
	@objc func signIn() {
		let provider = ASAuthorizationAppleIDProvider()
		let request = provider.createRequest()
		request.requestedScopes = [.fullName]
		
		let controller = ASAuthorizationController(authorizationRequests: [request])
		
		controller.delegate = self
		controller.presentationContextProvider = self
		controller.performRequests()
	}
	
	//Returns true if a user already exists
	private func userExists(id: String, completion: @escaping (Bool) -> Void) {
		let predicate = NSPredicate(format: "id == %@", id)
		let query = CKQuery(recordType: "Profiles", predicate: predicate)
		
		db.getRecords(query: query) { returnedRecords in
			completion(!returnedRecords.isEmpty)
		}
	}
	
	//Returns true if a user hasn't set up their profile yet
	private func cleanProfile(id: String, completion: @escaping (Bool) -> Void) {
		let predicate = NSPredicate(format: "id == %@", id)
		let query = CKQuery(recordType: "Profiles", predicate: predicate)
		
		db.getRecords(query: query) { returnedRecords in
			if returnedRecords[0]["ageRange"] == nil {
				completion(true)
			}
			else {
				completion(false)
			}
		}
	}
	
	// MARK: - Other
	
	//Shows view controller with given identifier
	private func showVC(identifier: String) {
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

// MARK: - Extensions

extension LoginVC: ASAuthorizationControllerDelegate {
	//Authorization error
	func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
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
			
			//Check if it's a new user
			userExists(id: id) { [weak self] newUser in
				if !newUser {
					//Get user's full name from iCloud
					let firstName = credentials.fullName?.givenName
					let lastName = credentials.fullName?.familyName
					
					//Create profile record
					let profileRecord = CKRecord(recordType: "Profiles")
					profileRecord["id"] = id
					profileRecord["firstName"] = firstName
					profileRecord["lastName"] = lastName
					profileRecord["xp"] = 0
					
					//Save profile record
					self?.db.saveRecord(record: profileRecord) { [weak self] saved in
						if !saved {
							DispatchQueue.main.async {
								self?.showAlert(title: "Error while signing in", message: "Try again later")
							}
						}
						else {
							DispatchQueue.main.async {
								UserDefaults.standard.set(id, forKey: "userID")
								AppDelegate.get().setCurrentUser(id)
								self?.showVC(identifier: "accountCreation")
							}
						}
					}
				}
				else {
					//Check if user has set up their profile
					self?.cleanProfile(id: id) { [weak self] clean in
						if clean {
							DispatchQueue.main.async {
								UserDefaults.standard.set(id, forKey: "userID")
								AppDelegate.get().setCurrentUser(id)
								self?.showVC(identifier: "accountCreation")
							}
						}
						else {
							DispatchQueue.main.async {
								//AppDelegate.get().setCurrentUser("aliceID")
								//UserDefaults.standard.set("aliceID", forKey: "userID")
								
								UserDefaults.standard.set(id, forKey: "userID")
								AppDelegate.get().setCurrentUser(id)
								AppDelegate.get().setDesiredTabIndex(1)
								self?.showVC(identifier: "tabController")
							}
						}
					}
				}
			}
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
