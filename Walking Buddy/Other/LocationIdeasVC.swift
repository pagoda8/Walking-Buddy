//
//  LocationIdeasVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 04/04/2023.
//
//	Implements the location ideas view controller

import UIKit
import CoreLocation
import Contacts

class LocationIdeasVC: UIViewController {
	
	//Shows that location ideas are being generated
	private let activityIndicator = UIActivityIndicatorView(style: .medium)
	
	//An array of inputs for generating location ideas
	private let inputArray = [
		"What interesting places can I see near ",
		"Are there any events happening near ",
		"What things can I do near ",
		"What are the best places to visit near ",
		"What are the top attractions near "
	]
	
	//Text view showing generated location ideas
	@IBOutlet weak var textView: UITextView!
	//Button to genarate new location ideas
	@IBOutlet weak var refreshButton: UIButton!
	
	// MARK: - View functions
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		//Set up activity indicator
		view.addSubview(activityIndicator)
		activityIndicator.translatesAutoresizingMaskIntoConstraints = false
		activityIndicator.centerXAnchor.constraint(equalTo: refreshButton.centerXAnchor).isActive = true
		activityIndicator.centerYAnchor.constraint(equalTo: refreshButton.centerYAnchor).isActive = true
		activityIndicator.backgroundColor = UIColor(white: 0, alpha: 0)
		activityIndicator.color = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
		activityIndicator.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
		
		generateIdeas()
	}

	// MARK: - IBActions
	
	//When the my profile button is tapped
	@IBAction func myProfile(_ sender: Any) {
		AppDelegate.get().setDesiredTabIndex(3)
		showVC(identifier: "tabController")
	}
	
	//When the refresh button is tapped
	@IBAction func refresh(_ sender: Any) {
		vibrate(style: .light)
		generateIdeas()
	}
	
	// MARK: - Functions
	
	//Generate random location ideas
	private func generateIdeas() {
		//Get user location
		guard let userCoordinate = AppDelegate.get().getRecentUserLocation() else {
			showLocationAlert()
			return
		}
		let userLocation = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
		
		let inputArray = inputArray
		refreshButton.isHidden = true
		activityIndicator.startAnimating()
		
		//Get address from user location
		CLGeocoder().reverseGeocodeLocation(userLocation) { [weak self] (placemarks, error) in
			guard let placemark = placemarks?.first else {
				DispatchQueue.main.async {
					self?.activityIndicator.stopAnimating()
					self?.refreshButton.isHidden = false
					self?.textView.text = "Failed to generate location ideas. Try again later."
				}
				return
			}
			
			let postalAddressFormatter = CNPostalAddressFormatter()
			postalAddressFormatter.style = .mailingAddress
			guard let postalAddress = placemark.postalAddress else {
				DispatchQueue.main.async {
					self?.activityIndicator.stopAnimating()
					self?.refreshButton.isHidden = false
					self?.textView.text = "Failed to generate location ideas. Try again later."
				}
				return
			}
			let stringAddress = postalAddressFormatter.string(from: postalAddress)
			
			//Once address is retrieved, generate location ideas
			let randomIndex = Int.random(in: 0..<inputArray.count)
			let inputPrefix = inputArray[randomIndex]
			let inputToShow = inputPrefix + "my location?"
			let inputToUse = inputPrefix + "the location of " + stringAddress + "?"
			
			OpenAICaller.shared.getResponse(input: inputToUse) { [weak self] responseState in
				switch responseState {
				case .success(let output):
					DispatchQueue.main.async {
						self?.textView.text = inputToShow + output
					}
				case .failure:
					DispatchQueue.main.async {
						self?.textView.text = "Failed to generate location ideas. Try again later."
					}
				}
				DispatchQueue.main.async {
					self?.activityIndicator.stopAnimating()
					self?.refreshButton.isHidden = false
				}
			}
		}
	}
	
	// MARK: - Custom alerts
	
	//Shows alert giving information about using location and option to go to Settings or cancel
	private func showLocationAlert() {
		vibrate(style: .light)
		let alert = UIAlertController(title: "Precise location required", message: "Without precise location the location ideas cannot be generated", preferredStyle: .alert)
		
		let goToSettings = UIAlertAction(title: "Go to Settings", style: .default) { [weak self] _ in
			guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
				self?.showAlert(title: "Error", message: "Cannot open Settings app")
				return
			}
			if (UIApplication.shared.canOpenURL(settingsURL)) {
				UIApplication.shared.open(settingsURL)
			} else {
				self?.showAlert(title: "Error", message: "Cannot open Settings app")
			}
		}
		let cancel = UIAlertAction(title: "Cancel", style: .default)
		
		alert.addAction(cancel)
		alert.addAction(goToSettings)
		self.present(alert, animated: true)
	}
	
	// MARK: - Other
	
	//Shows view controller with given identifier
	private func showVC(identifier: String) {
		AppDelegate.get().filterNavigationStack(identifier)
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
