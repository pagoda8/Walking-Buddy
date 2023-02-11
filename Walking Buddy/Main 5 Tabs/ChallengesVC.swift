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
		//TODO
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
		
		//TODO
		
		//Set selection highlight colour
		let bgColourView = UIView()
		bgColourView.backgroundColor = UIColor.lightGray
		cell.selectedBackgroundView = bgColourView
		
		return cell
	}
}
