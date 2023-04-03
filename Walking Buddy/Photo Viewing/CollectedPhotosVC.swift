//
//  CollectedPhotosVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 26/03/2023.
//
//	Implements the collected photos view controller

import UIKit
import CloudKit

class CollectedPhotosVC: UIViewController {
	
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

	@IBOutlet weak var collectionView: UICollectionView! //Collection view showing collected photos
	@IBOutlet weak var titleLabel: UILabel! //Label showing title on top bar
	@IBOutlet weak var noPhotosLabel: UILabel! //Label shown when there are no collected photos

	// MARK: - View functions
	
	override func viewDidLoad() {
		super.viewDidLoad()
		initialSetup()
		
		//Set up collection view
		let layout = UICollectionViewFlowLayout()
		layout.itemSize = cellItemSize
		collectionView.collectionViewLayout = layout
		collectionView.register(CollectedPhotosCollectionVC.nib(), forCellWithReuseIdentifier: "collectedPhotosCell")
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
	
	//Fetches collected photos from db
	private func fetchData() {
		noPhotosLabel.isHidden = true
		var fetchedPhotoIDsArray: [String] = []
		var fetchedPhotosArray: [UIImage] = []
		let group = DispatchGroup()
		let userID = userIDForPhotos
		let imageSize = cellItemSize
		
		let predicate = NSPredicate(format: "userID == %@", userID)
		let query = CKQuery(recordType: "CollectedPhotos", predicate: predicate)
		query.sortDescriptors = [NSSortDescriptor(key: "lastCollected", ascending: false)]
		
		group.enter()
		db.getRecords(query: query) { [weak self] returnedRecords in
			//Initialise arrays with empty data
			for _ in returnedRecords {
				fetchedPhotoIDsArray.append(String())
				fetchedPhotosArray.append(UIImage())
			}
			
			//Loop through collected photos
			for i in 0..<returnedRecords.count {
				let collectedPhotoRecord = returnedRecords[i]
				let photoID = collectedPhotoRecord["photoID"] as! String
				let photoRecordID = CKRecord.ID(recordName: photoID)
				let predicate = NSPredicate(format: "recordID == %@", photoRecordID)
				let query = CKQuery(recordType: "Photos", predicate: predicate)
				
				//Get the photo referenced by the collected photo record
				group.enter()
				self?.db.getRecords(query: query) { returnedRecords in
					let photoRecord = returnedRecords[0]
					let imageAsset = photoRecord["photo"] as? CKAsset
					
					if let imageUrl = imageAsset?.fileURL,
					   let image = ImageTool.downsample(imageAt: imageUrl, to: imageSize) {
						//If photo retrieved successfully, insert at correct index and remove empty data
						fetchedPhotoIDsArray.insert(photoRecord.recordID.recordName, at: i)
						fetchedPhotoIDsArray.remove(at: i + 1)
						fetchedPhotosArray.insert(image, at: i)
						fetchedPhotosArray.remove(at: i + 1)
					}
					group.leave()
				}
			}
			group.leave()
		}
		
		group.notify(queue: .main) {
			//Remove any empty data in case some photos were not retrieved
			var i = 0
			for photoID in fetchedPhotoIDsArray {
				if photoID == "" {
					fetchedPhotoIDsArray.remove(at: i)
					fetchedPhotosArray.remove(at: i)
				}
				else {
					i += 1
				}
			}
			
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
	
	//Shows view controller with given identifier
	private func showVC(identifier: String) {
		AppDelegate.get().filterNavigationStack(identifier)
		let vc = self.storyboard?.instantiateViewController(withIdentifier: identifier)
		vc?.modalPresentationStyle = .overFullScreen
		self.present(vc!, animated: true)
	}
}

// MARK: - Collection view setup

extension CollectedPhotosVC: UICollectionViewDelegate, UICollectionViewDataSource {
	//When item is selected
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let photoID = photoIDsArray[indexPath.item]
		
		if !AppDelegate.get().isPhotoDeletionInProgress(photoID) {
			AppDelegate.get().setPhotoToOpen(photoID)
			AppDelegate.get().setVCIDOfCaller("photosTabController")
			AppDelegate.get().setDesiredPhotosTabIndex(1)
			showVC(identifier: "photoDetails")
		}
		
		collectionView.deselectItem(at: indexPath, animated: true)
	}
	
	//Returns number of items for section
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return photosArray.count
	}
	
	//Creates and returns a cell
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectedPhotosCell", for: indexPath) as! CollectedPhotosCollectionVC
		
		cell.configure(with: photosArray[indexPath.item])
		
		return cell
	}
}

extension CollectedPhotosVC: UICollectionViewDelegateFlowLayout {
	//Returns a size for an item
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return cellItemSize
	}
}
