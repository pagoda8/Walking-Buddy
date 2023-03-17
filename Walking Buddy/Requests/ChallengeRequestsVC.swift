//
//  ChallengeRequestsVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 09/02/2023.
//
//	Implements the challenge requests view controller

import UIKit
import CloudKit

class ChallengeRequestsVC: UIViewController {

	//Reference to db manager
	private let db = DBManager.shared
	
	//Stores records with challenge requests
	private var requestsArray: [CKRecord] = []
	
	//Stores records with profiles of challenge request senders
	private var senderProfilesArray: [CKRecord] = []
	
	//Controls refreshing of table view
	private let refreshControl = UIRefreshControl()
	
	//Shows a list of challenge requests
	@IBOutlet var tableView: UITableView!
	
	//Label shown when there are no challenge requests
	@IBOutlet weak var noRequestsLabel: UILabel!
	
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
    
	// MARK: - IBActions
	
	//When My profile button is tapped
	@IBAction func myProfile(_ sender: Any) {
		AppDelegate.get().setDesiredTabIndex(4)
		showVC(identifier: "tabController")
	}
	
	// MARK: - Functions
	
	//Gets challenge requests and the profiles of senders from db
	private func fetchData() {
		noRequestsLabel.isHidden = true
		
		let id = AppDelegate.get().getCurrentUser()
		let group = DispatchGroup()
		var fetchedRequestsArray: [CKRecord] = []
		var fetchedSenderProfilesArray: [CKRecord] = []
		
		let predicate = NSPredicate(format: "receiverID == %@", id)
		let query = CKQuery(recordType: "ChallengeRequests", predicate: predicate)
		//Get requests sorted by creation date (new first)
		query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
		
		group.enter()
		self.db.getRecords(query: query) { returnedRecords in
			fetchedRequestsArray = returnedRecords
			group.leave()
		}
		
		group.notify(queue: .main) {
			var arrayCount = fetchedRequestsArray.count
			if arrayCount > 0 {
				let arrayEndIndex = arrayCount - 1
				let group2 = DispatchGroup()
				
				//Initialise sender profile array with blank records
				for _ in fetchedRequestsArray {
					fetchedSenderProfilesArray.append(CKRecord(recordType: "Profiles"))
				}
				
				//Loop over challenge requests
				group2.enter()
				for i in 0...arrayEndIndex {
					//Get the profile record of sender
					let profileID = fetchedRequestsArray[i]["senderID"] as! String
					let predicate = NSPredicate(format: "id == %@", profileID)
					let query = CKQuery(recordType: "Profiles", predicate: predicate)
					
					group2.enter()
					self.db.getRecords(query: query) { returnedRecords in
						let profileRecord = returnedRecords[0]
						fetchedSenderProfilesArray.insert(profileRecord, at: i)
						fetchedSenderProfilesArray.remove(at: i + 1) //remove blank profile
						group2.leave()
					}
				}
				group2.leave()
				
				group2.notify(queue: .main) {
					self.senderProfilesArray = fetchedSenderProfilesArray
					self.requestsArray = fetchedRequestsArray
					self.tableView.reloadData()
					self.refreshControl.endRefreshing()
					self.noRequestsLabel.isHidden = !self.requestsArray.isEmpty
				}
			}
			else {
				self.senderProfilesArray = fetchedSenderProfilesArray
				self.requestsArray = fetchedRequestsArray
				self.tableView.reloadData()
				self.refreshControl.endRefreshing()
				self.noRequestsLabel.isHidden = !self.requestsArray.isEmpty
			}
		}
	}
	
	//Returns an end date for a challenge given the challenge duration in minutes
	private func createEndDateFromChallengeMinutes(minutes: Int64) -> Date? {
		let d = minutes / (24 * 60)
		let h = (minutes - (d * 24 * 60)) / 60
		let m = minutes - (d * 24 * 60 + h * 60)
		
		var dateComponents = DateComponents()
		dateComponents.day = Int(d)
		dateComponents.hour = Int(h)
		dateComponents.minute = Int(m)
		let endDate = Calendar.current.date(byAdding: dateComponents, to: Date())
		
		return endDate
	}
	
	//Creates a string with readable time given a number of minutes
	private func createTimeStringFromMinutes(minutes: Int64) -> String {
		let d = minutes / (24 * 60)
		let h = (minutes - (d * 24 * 60)) / 60
		let m = minutes - (d * 24 * 60 + h * 60)
		let dString = (d == 0) ? "" : " " + String(d) + "d"
		let hString = (h == 0) ? "" : " " + String(h) + "h"
		var mString = (m == 0) ? "" : " " + String(m) + "m"
		
		return dString + hString + mString
	}
	
	// MARK: - Custom alerts
	
	//Shows action sheet with options to accept or deny a challenge request
	private func showChallengeAlert(completion: @escaping (Bool?) -> Void) {
		vibrate(style: .light)
		let actionSheet = UIAlertController(title: "Select action", message: "Select what to do with this challenge request", preferredStyle: .actionSheet)
		actionSheet.addAction(UIAlertAction(title: "Accept", style: .default, handler: { _ in completion(true) }))
		actionSheet.addAction(UIAlertAction(title: "Deny", style: .destructive, handler: { _ in completion(false) }))
		actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in completion(nil) }))
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

// MARK: - Table view setup

extension ChallengeRequestsVC: UITableViewDelegate, UITableViewDataSource {
	//When row in table is tapped
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		showChallengeAlert() { accept in
			if accept == nil {
				tableView.deselectRow(at: indexPath, animated: true)
			}
			else if accept == true {
				tableView.isUserInteractionEnabled = false
				tableView.deselectRow(at: indexPath, animated: true)
				
				var challengeRunningWithPerson = false
				let group1 = DispatchGroup()
				
				let requestRecord = self.requestsArray[indexPath.row]
				let ourID = requestRecord["receiverID"] as! String
				let senderID = requestRecord["senderID"] as! String
				let minutesTotal = requestRecord["minutes"] as! Int64
				
				//Check for running challenges with person 1
				let predicate1 = NSPredicate(format: "id1 == %@ AND id2 == %@", ourID, senderID)
				let query1 = CKQuery(recordType: "Challenges", predicate: predicate1)
				group1.enter()
				self.db.getRecords(query: query1) { returnedRecords in
					if !returnedRecords.isEmpty {
						challengeRunningWithPerson = true
					}
					group1.leave()
				}
				
				//Check for running challenges with person 2
				let predicate2 = NSPredicate(format: "id1 == %@ AND id2 == %@", senderID, ourID)
				let query2 = CKQuery(recordType: "Challenges", predicate: predicate2)
				group1.enter()
				self.db.getRecords(query: query2) { returnedRecords in
					if !returnedRecords.isEmpty {
						challengeRunningWithPerson = true
					}
					group1.leave()
				}
				
				group1.notify(queue: .main) {
					if challengeRunningWithPerson {
						self.tableView.isUserInteractionEnabled = true
						self.showAlert(title: "Unable to accept", message: "You already have an active challenge with this person")
					}
					else {
						let group2 = DispatchGroup()
						
						let endDate = self.createEndDateFromChallengeMinutes(minutes: minutesTotal)
						
						let challengeRecord = CKRecord(recordType: "Challenges")
						challengeRecord["id1"] = ourID
						challengeRecord["id2"] = senderID
						challengeRecord["xp1"] = 0
						challengeRecord["xp2"] = 0
						challengeRecord["end"] = endDate
						
						group2.enter()
						self.db.saveRecord(record: challengeRecord) { _ in
							group2.leave()
						}
						
						group2.enter()
						self.db.deleteRecord(record: requestRecord) { _ in
							group2.leave()
						}
						
						group2.notify(queue: .main) {
							self.fetchData()
							self.tableView.isUserInteractionEnabled = true
						}
					}
				}
			}
			else {
				tableView.isUserInteractionEnabled = false
				tableView.deselectRow(at: indexPath, animated: true)
				let group = DispatchGroup()
				var error = false
				
				let challengeRequest = self.requestsArray[indexPath.row]
				group.enter()
				self.db.deleteRecord(record: challengeRequest) { success in
					if !success {
						error = true
					}
					group.leave()
				}
				
				group.notify(queue: .main) {
					if error {
						self.tableView.isUserInteractionEnabled = true
						self.showAlert(title: "Error while denying challenge request", message: "Try again later")
					}
					else {
						self.fetchData()
						self.tableView.isUserInteractionEnabled = true
					}
				}
			}
		}
	}
	
	//Returns the row height
	public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 65
	}
	
	//Returns the number of rows for the table
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return requestsArray.count
	}
	
	//Creates and returns a cell
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		//Create cell from reusable cell
		let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell", for: indexPath) as! ChallengeRequestsTableVC
		let requestRecord = requestsArray[indexPath.row]
		let senderProfile = senderProfilesArray[indexPath.row]
		
		//Set image for cell
		let imageAsset = senderProfile["photo"] as? CKAsset
		if let imageUrl = imageAsset?.fileURL,
		   let data = try? Data(contentsOf: imageUrl),
		   let image = UIImage(data: data) {
			cell.profileImgView.image = image
		}
		
		//Set labels for cell
		let minutes = requestRecord["minutes"] as! Int64
		cell.timeLabel.text = createTimeStringFromMinutes(minutes: minutes)
		cell.nameLabel.text = (senderProfile["firstName"] as! String) + " " + (senderProfile["lastName"] as! String)
		
		//Set selection highlight colour
		let bgColourView = UIView()
		bgColourView.backgroundColor = UIColor.lightGray
		cell.selectedBackgroundView = bgColourView
		
		return cell
	}
}
