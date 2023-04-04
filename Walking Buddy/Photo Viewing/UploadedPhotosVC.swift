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
		
		//Long press for collection view
		let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(sender:)))
		collectionView.addGestureRecognizer(longPress)
		
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
		
		let width = (UIScreen.main.bounds.width - 40) / 2 - 5
		cellItemSize = CGSize(width: width, height: width)
	}
	
	//Fetches uploaded photos from db
	private func fetchData() {
		noPhotosLabel.isHidden = true
		var fetchedPhotoIDsArray: [String] = []
		var fetchedPhotosArray: [UIImage] = []
		let group = DispatchGroup()
		let userID = userIDForPhotos
		let imageSize = cellItemSize
		
		let predicate = NSPredicate(format: "authorID == %@", userID)
		let query = CKQuery(recordType: "Photos", predicate: predicate)
		query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
		
		group.enter()
		db.getRecords(query: query) { returnedRecords in
			for photoRecord in returnedRecords {
				let imageAsset = photoRecord["photo"] as? CKAsset
				if let imageUrl = imageAsset?.fileURL,
				   let image = ImageTool.downsample(imageAt: imageUrl, to: imageSize) {
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
	
	//Deletes a photo given an array index
	private func deletePhoto(arrayIndex: Int) {
		let group = DispatchGroup()
		let photoID = photoIDsArray[arrayIndex]
		AppDelegate.get().addPhotoDeletionInProgress(photoID)
		
		//Delete from collected photos
		let predicate = NSPredicate(format: "photoID == %@", photoID)
		let query = CKQuery(recordType: "CollectedPhotos", predicate: predicate)
		group.enter()
		db.getRecords(query: query) { [weak self] returnedRecords in
			for collectedPhotoRecord in returnedRecords {
				group.enter()
				self?.db.deleteRecord(record: collectedPhotoRecord) { _ in
					group.leave()
				}
			}
			group.leave()
		}
		
		//Delete from photos
		let photoRecordID = CKRecord.ID(recordName: photoID)
		let predicate2 = NSPredicate(format: "recordID == %@", photoRecordID)
		let query2 = CKQuery(recordType: "Photos", predicate: predicate2)
		group.enter()
		db.getRecords(query: query2) { [weak self] returnedRecords in
			let photoRecord = returnedRecords[0]
			group.enter()
			self?.db.deleteRecord(record: photoRecord) { _ in
				group.leave()
			}
			group.leave()
		}
		
		group.notify(queue: .main) {
			AppDelegate.get().deletePhotoDeletionInProgress(photoID)
			self.fetchData()
		}
	}
	
	// MARK: - Custom alerts
	
	//Shows action sheet with option to delete photo or cancel
	private func showDeleteActionSheet(arrayIndex: Int) {
		//Don't allow deletion if it's not our photo or deletion is in progress
		let userID = AppDelegate.get().getCurrentUser()
		if userIDForPhotos != userID || AppDelegate.get().isPhotoDeletionInProgress(photoIDsArray[arrayIndex]) {
			return
		}
		
		vibrate(style: .light)
		let actionSheet = UIAlertController(title: "Do you want to delete this photo?", message: "This cannot be undone", preferredStyle: .actionSheet)
		actionSheet.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in self.deletePhoto(arrayIndex: arrayIndex) }))
		actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		self.present(actionSheet, animated: true)
	}

	// MARK: - Other
	
	//Objective-C function to handle long press on collection view cell
	//Shows option to delete the photo
	@objc private func longPress(sender: UILongPressGestureRecognizer) {
		if (sender.state == UIGestureRecognizer.State.began) {
			let touchPoint = sender.location(in: collectionView)
			if let indexPath = collectionView.indexPathForItem(at: touchPoint) {
				showDeleteActionSheet(arrayIndex: indexPath.item)
			}
		}
	}
	
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
		let photoID = photoIDsArray[indexPath.item]
		
		if !AppDelegate.get().isPhotoDeletionInProgress(photoID) {
			AppDelegate.get().setPhotoToOpen(photoID)
			AppDelegate.get().setVCIDOfCaller("photosTabController")
			AppDelegate.get().setDesiredPhotosTabIndex(0)
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
	
	//Returns the edge insets for collection view
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		return UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
	}
}
