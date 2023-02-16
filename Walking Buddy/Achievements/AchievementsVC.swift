//
//  AchievementsVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 15/02/2023.
//

import UIKit
import CloudKit
import SwiftUI

class AchievementsVC: UIViewController {

	private let db = DBManager.shared
	
	private var achievementArray: [CKRecord] = []
	
	@IBOutlet var tableView: UITableView!
	
    override func viewDidLoad() {
        super.viewDidLoad()

		//Set up table view
		tableView.delegate = self
		tableView.dataSource = self
		tableView.showsVerticalScrollIndicator = false
		
		fetchData()
    }
	
	private func fetchData() {
		var fetchedAchievementArray: [CKRecord] = []
		let group = DispatchGroup()
		
		let id = AppDelegate.get().getCurrentUser()
		let predicate = NSPredicate(format: "id == %@", id)
		let query = CKQuery(recordType: "Achievements", predicate: predicate)
		
		group.enter()
		db.getRecords(query: query) { returnedRecords in
			fetchedAchievementArray = returnedRecords
			group.leave()
		}
		
		group.notify(queue: .main) {
			self.achievementArray = fetchedAchievementArray
			self.tableView.reloadData()
		}
	}
	
	//When My profile button is tapped
	@IBAction func myProfile(_ sender: Any) {
		AppDelegate.get().setDesiredTabIndex(4)
		showVC(identifier: "tabController")
	}
	
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

//Table view setup

extension AchievementsVC: UITableViewDelegate {
	//When row is tapped
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		//tableView.deselectRow(at: indexPath, animated: false)
	}
	
	//Returns row height
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 100
	}
}

extension AchievementsVC: UITableViewDataSource {
	//Number of rows
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return achievementArray.count
	}
	
	//Creates cell
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell") as! AchievementsTableVC
		var competitorRecord = CKRecord(recordType: "Achievements")
		var collectorRecord = CKRecord(recordType: "Achievements")
		let level1Threshold = 5
		let level2Threshold = 15
		let level3Threshold = 50
		
		if achievementArray[0]["name"] == "competitor" {
			competitorRecord = achievementArray[0]
			collectorRecord = achievementArray[1]
		}
		else {
			competitorRecord = achievementArray[1]
			collectorRecord = achievementArray[0]
		}
		
		if indexPath.row == 0 {
			let amount = collectorRecord["amount"] as! Int64
			let level = collectorRecord["level"] as! Int64
			
			var threshold = 0
			switch level {
			case 0:
				threshold = level1Threshold
			case 1:
				threshold = level2Threshold
				cell.star1.image = UIImage(systemName: "star.fill")
			case 2:
				threshold = level3Threshold
				cell.star1.image = UIImage(systemName: "star.fill")
				cell.star2.image = UIImage(systemName: "star.fill")
			default:
				threshold = level3Threshold
				cell.star1.image = UIImage(systemName: "star.fill")
				cell.star2.image = UIImage(systemName: "star.fill")
				cell.star3.image = UIImage(systemName: "star.fill")
			}
			
			cell.icon.image = UIImage(systemName: "photo")
			cell.name.text = "The collector"
			cell.achievementDescription.text = "Collect " + String(threshold) + " photos"
			cell.progressView.progress = Float(amount) / Float(threshold)
			cell.progressLabel.text = String(amount) + "/" + String(threshold)
			
		}
		else if indexPath.row == 1 {
			let amount = competitorRecord["amount"] as! Int64
			let level = competitorRecord["level"] as! Int64
			
			var threshold = 0
			switch level {
			case 0:
				threshold = level1Threshold
			case 1:
				threshold = level2Threshold
				cell.star1.image = UIImage(systemName: "star.fill")
			case 2:
				threshold = level3Threshold
				cell.star1.image = UIImage(systemName: "star.fill")
				cell.star2.image = UIImage(systemName: "star.fill")
			default:
				threshold = level3Threshold
				cell.star1.image = UIImage(systemName: "star.fill")
				cell.star2.image = UIImage(systemName: "star.fill")
				cell.star3.image = UIImage(systemName: "star.fill")
			}
			
			cell.icon.image = UIImage(systemName: "timer")
			cell.name.text = "The competitor"
			cell.achievementDescription.text = "Win " + String(threshold) + " challenges"
			cell.progressView.progress = Float(amount) / Float(threshold)
			cell.progressLabel.text = String(amount) + "/" + String(threshold)
		}
		
		return cell
	}
}
