//
//  LocationIdeasVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 04/04/2023.
//
//	Implements the location ideas view controller

import UIKit

class LocationIdeasVC: UIViewController {
	
	//Shows that location ideas are being generated
	private let activityIndicator = UIActivityIndicatorView(style: .medium)
	
	//An array of inputs for generating location ideas
	private let inputArray = [
		"How can I live a healthier life?",
		"How can I improve my body's health?",
		"How to be physically active while having a busy lifestyle?",
		"Which foods will give me more energy?",
		"What healthy foods can I add to my diet?",
		"What are some good habits to increase my health?",
		"What can I do everyday to be healthier?",
		"How to do more steps during my day?",
		"How can I increase the amount of physical exercise?",
		"What are the most important vitamins for my health?"
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
		refreshButton.isHidden = true
		activityIndicator.startAnimating()
		
		let randomIndex = Int.random(in: 0..<inputArray.count)
		let input = inputArray[randomIndex]
		
		OpenAICaller.shared.getResponse(input: input) { [weak self] responseState in
			switch responseState {
			case .success(let output):
				DispatchQueue.main.async {
					self?.textView.text = input + output
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
