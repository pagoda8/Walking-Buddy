//
//  HealthTipsVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 19/03/2023.
//
//	Implements the health tips view controller

import UIKit

class HealthTipsVC: UIViewController {

	//Text view showing generated health tips
	@IBOutlet weak var textView: UITextView!
	
	//Button to genarate new health tips
	@IBOutlet weak var refreshButton: UIButton!
	
	//Shows that health tips are being generated
	private let activityIndicator = UIActivityIndicatorView(style: .medium)
	
	//An array of inputs for generating health tips
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
		
		generateTips()
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
		generateTips()
	}
	
	// MARK: - Functions
	
	//Generate random health tips
	private func generateTips() {
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
					self?.textView.text = "Failed to generate health tips. Try again later."
				}
			}
			DispatchQueue.main.async {
				self?.activityIndicator.stopAnimating()
				self?.refreshButton.isHidden = false
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
