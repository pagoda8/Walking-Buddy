//
//  ChallengesVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 08/02/2023.
//
//	Implements the Challenges View Controller

import UIKit
import CloudKit

class ChallengesVC: UIViewController {

	//Reference to db manager
	private let db = DBManager.shared
	
	private var challengesArray: [CKRecord] = [] //Holds chellenges records involving user
	private var profilesArray: [CKRecord] = [] //Holds profile records of user's competitors
	//Reference to current user's profile record
	private var myProfileRecord: CKRecord = CKRecord(recordType: "Profiles")
	
	//Controls refreshing of table view
	private let refreshControl = UIRefreshControl()
	
	//Shows a list of challenges
	@IBOutlet weak var tableView: UITableView!
	
	//Label shown when there are no active challenges
	@IBOutlet weak var noChallengesLabel: UILabel!
	
	// MARK: - View functions
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		//Set up table view
		tableView.delegate = self
		tableView.dataSource = self
		tableView.showsVerticalScrollIndicator = false
		
		//Set up refresh control
		tableView.refreshControl = refreshControl
		tableView.backgroundView = refreshControl
		refreshControl.addTarget(self, action: #selector(refreshTable(_:)), for: .valueChanged)
		refreshControl.tintColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
		
		fetchData()
    }
	
	// MARK: - Functions
	
	//Fetches challenges and profile records from db
	private func fetchData() {
		noChallengesLabel.isHidden = true
		
		//Get user's profile record
		let ourID = AppDelegate.get().getCurrentUser()
		let predicate = NSPredicate(format: "id == %@", ourID)
		let query = CKQuery(recordType: "Profiles", predicate: predicate)
		
		let group1 = DispatchGroup()
		group1.enter()
		self.db.getRecords(query: query) { [weak self] returnedRecords in
			DispatchQueue.main.async {
				self?.myProfileRecord = returnedRecords[0]
			}
			group1.leave()
		}
		
		group1.notify(queue: .main) {
			var fetchedChallengesArray: [CKRecord] = []
			var fetchedProfilesArray: [CKRecord] = []
			
			//Get challenge records 1
			let predicate1 = NSPredicate(format: "id1 == %@", ourID)
			let query1 = CKQuery(recordType: "Challenges", predicate: predicate1)
			
			let group2 = DispatchGroup()
			group2.enter()
			self.db.getRecords(query: query1) { [weak self] returnedRecords in
				var localChallengesArray = returnedRecords
				
				var i = 0
				for challenge in localChallengesArray {
					//Check if challenge has ended
					let endDate = challenge["end"] as! Date
					let currentDate = Date()
					let interval = endDate - currentDate
					
					if interval <= 0 {
						DispatchQueue.main.async {
							self?.endChallenge(challengeRecord: challenge)
						}
						localChallengesArray.remove(at: i)
					}
					else {
						i += 1
					}
				}
				fetchedChallengesArray.append(contentsOf: localChallengesArray)
				group2.leave()
			}
			
			//Get challenge records 2
			let predicate2 = NSPredicate(format: "id2 == %@", ourID)
			let query2 = CKQuery(recordType: "Challenges", predicate: predicate2)
			
			group2.enter()
			self.db.getRecords(query: query2) { [weak self] returnedRecords in
				var localChallengesArray = returnedRecords
				
				var i = 0
				for challenge in localChallengesArray {
					//Check if challenge has ended
					let endDate = challenge["end"] as! Date
					let currentDate = Date()
					let interval = endDate - currentDate
					
					if interval <= 0 {
						DispatchQueue.main.async {
							self?.endChallenge(challengeRecord: challenge)
						}
						localChallengesArray.remove(at: i)
					}
					else {
						i += 1
					}
				}
				fetchedChallengesArray.append(contentsOf: localChallengesArray)
				group2.leave()
			}
			
			//Fetching challenges records complete
			group2.notify(queue: .main) {
				//Sort challenges by end date (ascending)
				fetchedChallengesArray = fetchedChallengesArray.sorted { ($0.value(forKey: "end") as! Date) < ($1.value(forKey: "end") as! Date) }
				
				let arrayCount = fetchedChallengesArray.count
				if arrayCount > 0 {
					let arrayEndIndex = arrayCount - 1
					let group3 = DispatchGroup()
					
					//Initialise profile array with blank records
					for _ in fetchedChallengesArray {
						fetchedProfilesArray.append(CKRecord(recordType: "Profiles"))
					}
					
					//Loop over challenge requests
					group3.enter()
					for i in 0...arrayEndIndex {
						//Get the profile ID of competitor
						var competitorProfileID: String
						let id1 = fetchedChallengesArray[i]["id1"] as! String
						if id1 == ourID {
							competitorProfileID = fetchedChallengesArray[i]["id2"] as! String
						}
						else {
							competitorProfileID = id1
						}
						
						//Get the competitor's profile record
						let predicate = NSPredicate(format: "id == %@", competitorProfileID)
						let query = CKQuery(recordType: "Profiles", predicate: predicate)
						group3.enter()
						self.db.getRecords(query: query) { returnedRecords in
							let profileRecord = returnedRecords[0]
							fetchedProfilesArray.insert(profileRecord, at: i)
							fetchedProfilesArray.remove(at: i + 1) //remove blank profile
							group3.leave()
						}
					}
					group3.leave()
					
					group3.notify(queue: .main) {
						self.profilesArray = fetchedProfilesArray
						self.challengesArray = fetchedChallengesArray
						self.tableView.reloadData()
						self.refreshControl.endRefreshing()
						self.noChallengesLabel.isHidden = !self.challengesArray.isEmpty
					}
				}
				else {
					self.profilesArray = fetchedProfilesArray
					self.challengesArray = fetchedChallengesArray
					self.tableView.reloadData()
					self.refreshControl.endRefreshing()
					self.noChallengesLabel.isHidden = !self.challengesArray.isEmpty
				}
			}
		}
	}
	
	//Called to end a challenge and give reward(s)
	private func endChallenge(challengeRecord: CKRecord) {
		let xp1 = challengeRecord["xp1"] as! Int64
		let xp2 = challengeRecord["xp2"] as! Int64
		let id1 = challengeRecord["id1"] as! String
		let id2 = challengeRecord["id2"] as! String
		
		let group = DispatchGroup()
		group.enter()
		db.deleteRecord(record: challengeRecord) { _ in
			group.leave()
		}
		
		group.notify(queue: .main) {
			let reward = self.calculateReward(xp1: xp1, xp2: xp2)
			
			if xp1 == xp2 {
				self.awardXP(userID: id1, xp: reward)
				self.awardXP(userID: id2, xp: reward)
			}
			else if xp1 > xp2 {
				self.awardXP(userID: id1, xp: reward)
				self.updateCompetitorAchievement(userID: id1)
			}
			else {
				self.awardXP(userID: id2, xp: reward)
				self.updateCompetitorAchievement(userID: id2)
			}
		}
	}
	
	//Update competitor achievement of user when they win a challenge
	private func updateCompetitorAchievement(userID: String) {
		let predicate = NSPredicate(format: "id == %@ AND name == %@", userID, "competitor")
		let query = CKQuery(recordType: "Achievements", predicate: predicate)
		db.getRecords(query: query) { [weak self] returnedRecords in
			let achievementRecord = returnedRecords[0]
			
			//Update amount
			let currentAmount = achievementRecord["amount"] as! Int64
			let updatedAmount = currentAmount + 1
			achievementRecord["amount"] = updatedAmount
			
			//Update level
			let currentLevel = achievementRecord["level"] as! Int64
			if currentLevel == 0 && updatedAmount == 5 {
				achievementRecord["level"] = 1
			}
			else if currentLevel == 1 && updatedAmount == 15 {
				achievementRecord["level"] = 2
			}
			else if currentLevel == 2 && updatedAmount == 50 {
				achievementRecord["level"] = 3
			}
			
			self?.db.saveRecord(record: achievementRecord) { _ in }
		}
	}
	
	//Award a given user with XP points
	private func awardXP(userID: String, xp: Int) {
		let predicate = NSPredicate(format: "id == %@", userID)
		let query = CKQuery(recordType: "Profiles", predicate: predicate)
		db.getRecords(query: query) { [weak self] returnedRecords in
			let profileRecord = returnedRecords[0]
			let currentXP = profileRecord["xp"] as! Int64
			profileRecord["xp"] = currentXP + Int64(xp)
			
			self?.db.saveRecord(record: profileRecord) { _ in }
		}
	}

	//Calculates a reward for challenge winner based on collected XP
	private func calculateReward(xp1: Int64, xp2: Int64) -> Int {
		if xp1 == xp2 {
			let x = Double(xp1) / 4.0
			return Int(ceil(x))
		}
		else {
			let xp = max(xp1, xp2)
			return Int(xp / 2)
		}
	}
	
	//Returns a string with readable time given an amount of seconds
	private func createTimeStringFromSeconds(seconds: Int) -> String {
		let minutesTotal = seconds / 60
		let d = minutesTotal / (24 * 60)
		let h = (minutesTotal - (d * 24 * 60)) / 60
		let m = minutesTotal - (d * 24 * 60 + h * 60)
		let dString = (d == 0) ? "" : " " + String(d) + "d"
		let hString = (h == 0) ? "" : " " + String(h) + "h"
		var mString = (m == 0) ? "" : " " + String(m) + "m"
		if d == 0 && h == 0 && m == 0 {
			mString = "< 1m"
		}
		
		return dString + hString + mString
	}
	
	// MARK: - Custom alerts
	
	//Shows an action sheet with info about challenge
	private func showChallengeInfo(arrayIndex: Int) {
		vibrate(style: .light)
		let challengeRecord = challengesArray[arrayIndex]
		let xp1 = challengeRecord["xp1"] as! Int64
		let xp2 = challengeRecord["xp2"] as! Int64
		let reward = calculateReward(xp1: xp1, xp2: xp2)
		
		let width = UIScreen.main.bounds.width - 70
		let height = UIScreen.main.bounds.height / 7
		let vc = UIViewController()
		vc.preferredContentSize = CGSize(width: width, height: height)
		let textView = UITextView(frame: CGRect(x: 0, y: 0, width: width, height: height))
		textView.isEditable = false
		textView.isSelectable = false
		textView.textColor = UIColor(white: 0.7, alpha: 0.9)
		textView.font = UIFont.systemFont(ofSize: 17)
		textView.textAlignment = .center
		textView.layer.backgroundColor = UIColor(white: 0, alpha: 0).cgColor
		textView.text = "You can earn XP by collecting photos.\nThe winner will be awarded extra XP.\nReward is split in case of a draw.\n\n➤ Current reward: " + String(reward) + " XP"
		
		vc.view.addSubview(textView)
		textView.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor).isActive = true
		
		let actionSheet = UIAlertController(title: "Challenge Details", message: "", preferredStyle: .actionSheet)
		actionSheet.setValue(vc, forKey: "contentViewController")
		actionSheet.addAction(UIAlertAction(title: "OK", style: .cancel))
		self.present(actionSheet, animated: true)
	}
	
	// MARK: - Other
	
	//Objective-C function to refresh the table view. Used for refreshControl.
	@objc private func refreshTable(_ sender: Any) {
		fetchData()
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

// MARK: - Table View Setup

extension ChallengesVC: UITableViewDataSource, UITableViewDelegate {
	//When row is tapped
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		showChallengeInfo(arrayIndex: indexPath.row)
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	//Returns the row height
	public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 130
	}
	
	//Returns the number of rows for the table
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return challengesArray.count
	}
	
	//Creates and returns a cell
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell", for: indexPath) as! ChallengesTableVC
		let challengeRecord = challengesArray[indexPath.row]
		let competitorProfile = profilesArray[indexPath.row]
		let ourProfile = myProfileRecord
		
		//Set profile images
		let imageAsset1 = competitorProfile["photo"] as? CKAsset
		if let imageUrl = imageAsset1?.fileURL,
		   let data = try? Data(contentsOf: imageUrl),
		   let image = UIImage(data: data) {
			cell.imgView1.image = image
		}
		let imageAsset2 = ourProfile["photo"] as? CKAsset
		if let imageUrl = imageAsset2?.fileURL,
		   let data = try? Data(contentsOf: imageUrl),
		   let image = UIImage(data: data) {
			cell.imgView2.image = image
		}
		
		cell.name1Label.text = (competitorProfile["firstName"] as! String)
		
		//Set competitor XP on top label and our's on bottom
		if (challengeRecord["id1"] as! String) == (competitorProfile["id"] as! String) {
			cell.xp1Label.text = String(challengeRecord["xp1"] as! Int64) + " XP"
			cell.xp2Label.text = String(challengeRecord["xp2"] as! Int64) + " XP"
		}
		else {
			cell.xp1Label.text = String(challengeRecord["xp2"] as! Int64) + " XP"
			cell.xp2Label.text = String(challengeRecord["xp1"] as! Int64) + " XP"
		}
		
		//Set time left label
		let endDate = challengeRecord["end"] as! Date
		let currentDate = Date()
		let interval = Int(endDate - currentDate) //Seconds between dates
		cell.timeLabel.text = createTimeStringFromSeconds(seconds: interval)
		
		//Set selection highlight colour
		let bgColourView = UIView()
		bgColourView.backgroundColor = UIColor.lightGray
		cell.selectedBackgroundView = bgColourView
		
		return cell
	}
}
