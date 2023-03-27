//
//  UploadedPhotosVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 26/03/2023.
//
//	Implements the uploaded photos view controller

import UIKit
import CloudKit

class UploadedPhotosVC: UIViewController {
	
	//Reference to db manager
	private let db = DBManager.shared
	
	//ID of user whose photos the view will show
	private var userIDForPhotos = String()
	
	//Array with ID's of photos to display
	private var photoIDsArray: [String] = []
	
	//Array with photos to display
	private var photosArray: [UIImage] = []
	
	//Controls refreshing of collection view
	private let refreshControl = UIRefreshControl()
	
	//Size of a cell in collection view
	private var cellItemSize: CGSize = CGSize()

	@IBOutlet weak var collectionView: UICollectionView! //Collection view showing uploaded photos
	@IBOutlet weak var titleLabel: UILabel! //Label showing title on top bar
	@IBOutlet weak var noPhotosLabel: UILabel! //Label shown when there are no uploaded photos
	
	// MARK: - View functions
	
    override func viewDidLoad() {
        super.viewDidLoad()
		initialSetup()
		
		//Set up collection view
		let layout = UICollectionViewFlowLayout()
		layout.itemSize = cellItemSize
		collectionView.collectionViewLayout = layout
		collectionView.register(UploadedPhotosCollectionVC.nib(), forCellWithReuseIdentifier: "uploadedPhotosCell")
		collectionView.delegate = self
		collectionView.dataSource = self
		
		//Set up refresh control
		collectionView.refreshControl = refreshControl
		collectionView.backgroundView = refreshControl
		refreshControl.addTarget(self, action: #selector(refreshCollectionView(_:)), for: .valueChanged)
		refreshControl.tintColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
		
		//Fix tab bar colour bug
		self.view.layoutIfNeeded()
		
		fetchData()
    }

	// MARK: - IBActions
	
	//When back button is tapped
	@IBAction func back(_ sender: Any) {
		let vcid = AppDelegate.get().getVCIDOfCaller()
		showVC(identifier: vcid)
	}
	
	// MARK: - Functions
	
	//Performs initial setup
	private func initialSetup() {
		let vcidOfCaller = AppDelegate.get().fetchVCIDOfCaller()
		if vcidOfCaller == "tabController" {
			userIDForPhotos = AppDelegate.get().getCurrentUser()
			titleLabel.text = "My photos"
		}
		else {
			userIDForPhotos = AppDelegate.get().getUserProfileToOpen()
			titleLabel.text = "Photos"
		}
		
		let width = UIScreen.main.bounds.width / 2 - 5
		cellItemSize = CGSize(width: width, height: width)
	}
	
	//Fetches uploaded photos from db
	private func fetchData() {
		noPhotosLabel.isHidden = true
		var fetchedPhotoIDsArray: [String] = []
		var fetchedPhotosArray: [UIImage] = []
		let group = DispatchGroup()
		let userID = userIDForPhotos
		
		let predicate = NSPredicate(format: "authorID == %@", userID)
		let query = CKQuery(recordType: "Photos", predicate: predicate)
		query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
		
		group.enter()
		db.getRecords(query: query) { returnedRecords in
			for photoRecord in returnedRecords {
				let imageAsset = photoRecord["photo"] as? CKAsset
				if let imageUrl = imageAsset?.fileURL,
				   let data = try? Data(contentsOf: imageUrl),
				   let image = UIImage(data: data) {
					fetchedPhotoIDsArray.append(photoRecord.recordID.recordName)
					fetchedPhotosArray.append(image)
				}
			}
			group.leave()
		}
		
		group.notify(queue: .main) {
			self.photoIDsArray = fetchedPhotoIDsArray
			self.photosArray = fetchedPhotosArray
			self.collectionView.reloadData()
			self.refreshControl.endRefreshing()
			self.noPhotosLabel.isHidden = !self.photosArray.isEmpty
		}
	}

	// MARK: - Other
	
	//Objective-C function to refresh the collection view. Used for refreshControl.
	@objc private func refreshCollectionView(_ sender: Any) {
		fetchData()
	}
	
	//Shows alert with given title and message
	private func showAlert(title: String, message: String) {
		vibrate(style: .light)
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default))
		self.present(alert, animated: true)
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
}

// MARK: - Collection view setup

extension UploadedPhotosVC: UICollectionViewDelegate, UICollectionViewDataSource {
	//When item is selected
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		collectionView.deselectItem(at: indexPath, animated: true)
	}
	
	//Returns number of items for section
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return photosArray.count
	}
	
	//Creates and returns a cell
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "uploadedPhotosCell", for: indexPath) as! UploadedPhotosCollectionVC
		
		cell.configure(with: photosArray[indexPath.item])
		
		return cell
	}
}

extension UploadedPhotosVC: UICollectionViewDelegateFlowLayout {
	//Returns a size for an item
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return cellItemSize
	}
}
