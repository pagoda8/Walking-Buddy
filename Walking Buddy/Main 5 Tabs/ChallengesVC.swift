//
//  ChallengesVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 08/02/2023.
//

import UIKit
import CloudKit

class ChallengesVC: UIViewController {

	//Reference to db manager
	private let db = DBManager.shared
	
	private var challengesArray: [CKRecord] = []
	private var profilesArray: [CKRecord] = []
	private var myProfileRecord: CKRecord = CKRecord(recordType: "Profiles")
	
	//Controls refreshing of table view
	private let refreshControl = UIRefreshControl()
	
	//Shows a list of challenges
	@IBOutlet var tableView: UITableView!
	
	@IBOutlet weak var noChallengesLabel: UILabel!
	
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
	
	private func fetchData() {
		noChallengesLabel.isHidden = true
		
		let ourID = AppDelegate.get().getCurrentUser()
		let predicate = NSPredicate(format: "id == %@", ourID)
		let query = CKQuery(recordType: "Profiles", predicate: predicate)
		
		let group1 = DispatchGroup()
		group1.enter()
		self.db.getRecords(query: query) { returnedRecords in
			DispatchQueue.main.async {
				self.myProfileRecord = returnedRecords[0]
			}
			group1.leave()
		}
		
		group1.notify(queue: .main) {
			var fetchedChallengesArray: [CKRecord] = []
			var fetchedProfilesArray: [CKRecord] = []
			let group2 = DispatchGroup()
			
			let predicate1 = NSPredicate(format: "id1 == %@", ourID)
			let query1 = CKQuery(recordType: "Challenges", predicate: predicate1)
			group2.enter()
			self.db.getRecords(query: query1) { returnedRecords in
				var localChallengesArray = returnedRecords
				
				var i = 0
				for challenge in localChallengesArray {
					let endDate = challenge["end"] as! Date
					let currentDate = Date()
					let interval = endDate - currentDate
					if interval <= 0 {
						DispatchQueue.main.async {
							self.endChallenge(challengeRecord: challenge)
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
			
			let predicate2 = NSPredicate(format: "id2 == %@", ourID)
			let query2 = CKQuery(recordType: "Challenges", predicate: predicate2)
			group2.enter()
			self.db.getRecords(query: query2) { returnedRecords in
				var localChallengesArray = returnedRecords
				
				var i = 0
				for challenge in localChallengesArray {
					let endDate = challenge["end"] as! Date
					let currentDate = Date()
					let interval = endDate - currentDate
					if interval <= 0 {
						DispatchQueue.main.async {
							self.endChallenge(challengeRecord: challenge)
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
			
			group2.notify(queue: .main) {
				fetchedChallengesArray = fetchedChallengesArray.sorted { ($0.value(forKey: "end") as! Date) < ($1.value(forKey: "end") as! Date) }
				
				var arrayCount = fetchedChallengesArray.count
				if arrayCount > 0 {
					arrayCount -= 1
					
					//Initialise profile array with blank records
					for _ in fetchedChallengesArray {
						fetchedProfilesArray.append(CKRecord(recordType: "Profiles"))
					}
					
					let group3 = DispatchGroup()
					group3.enter()
					for i in 0...arrayCount {
						var profileID = ""
						let id1 = fetchedChallengesArray[i]["id1"] as! String
						if id1 == ourID {
							profileID = fetchedChallengesArray[i]["id2"] as! String
						}
						else {
							profileID = id1
						}
						
						let predicate = NSPredicate(format: "id == %@", profileID)
						let query = CKQuery(recordType: "Profiles", predicate: predicate)
						group3.enter()
						self.db.getRecords(query: query) { returnedRecords in
							let profile = returnedRecords[0]
							fetchedProfilesArray.insert(profile, at: i)
							fetchedProfilesArray.remove(at: i + 1)
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
		
	}

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

//Table view setup

extension ChallengesVC: UITableViewDelegate {
	//When row is tapped
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		//TODO
		
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	//Returns the row height
	public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 130
	}
}

extension ChallengesVC: UITableViewDataSource {
	//Returns the number of rows for the table
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return challengesArray.count
	}
	
	//Creates and returns a cell
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell", for: indexPath) as! ChallengesTableVC
		let challengeRecord = challengesArray[indexPath.row]
		let personProfile = profilesArray[indexPath.row]
		let ourProfile = myProfileRecord
		
		let imageAsset1 = personProfile["photo"] as? CKAsset
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
		
		cell.name1Label.text = (personProfile["firstName"] as! String)
		
		if (challengeRecord["id1"] as! String) == (personProfile["id"] as! String) {
			cell.xp1Label.text = String(challengeRecord["xp1"] as! Int64) + " XP"
			cell.xp2Label.text = String(challengeRecord["xp2"] as! Int64) + " XP"
		}
		else {
			cell.xp1Label.text = String(challengeRecord["xp2"] as! Int64) + " XP"
			cell.xp2Label.text = String(challengeRecord["xp1"] as! Int64) + " XP"
		}
		
		let endDate = challengeRecord["end"] as! Date
		let currentDate = Date()
		let interval = Int(endDate - currentDate) //Seconds between dates
		let minutesTotal = interval / 60
		let d = minutesTotal / (24 * 60)
		let h = (minutesTotal - (d * 24 * 60)) / 60
		let m = minutesTotal - (d * 24 * 60 + h * 60)
		let dString = (d == 0) ? "" : " " + String(d) + "d"
		let hString = (h == 0) ? "" : " " + String(h) + "h"
		let mString = (m == 0) ? "" : " " + String(m) + "m"
		cell.timeLabel.text = dString + hString + mString
		
		//Set selection highlight colour
		let bgColourView = UIView()
		bgColourView.backgroundColor = UIColor.lightGray
		cell.selectedBackgroundView = bgColourView
		
		return cell
	}
}
