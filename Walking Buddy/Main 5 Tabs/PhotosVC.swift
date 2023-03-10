//
//  PhotosVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 30/01/2023.
//
//	Implements the Photos Tab View Controller

import UIKit
import MapKit
import CloudKit
import CryptoKit
import AVFoundation
import Photos

class PhotosVC: UIViewController {
	
	//Reference to db manager
	private let db = DBManager.shared
	
	//True if it is the first time the view is shown
	private var viewFirstLoad = true
	//True if the user uses camera to upload a photo
	private var uploadUsingCamera = false
	
	@IBOutlet weak var searchBar: UISearchBar!
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var addButton: UIButton!
	
	//Used to show that photo is uploading
	private let activityIndicator = UIActivityIndicatorView(style: .medium)
	
	private var photosArray: [CKRecord] = []
	
	private let locationManager: LocationManager = LocationManager.shared
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		//Set up activity indicator
		view.addSubview(activityIndicator)
		activityIndicator.translatesAutoresizingMaskIntoConstraints = false
		activityIndicator.centerXAnchor.constraint(equalTo: addButton.centerXAnchor).isActive = true
		activityIndicator.centerYAnchor.constraint(equalTo: addButton.centerYAnchor).isActive = true
		activityIndicator.backgroundColor = UIColor(white: 0, alpha: 0)
		activityIndicator.color = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
		activityIndicator.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
		
		mapView.delegate = self
		mapView.mapType = .hybrid //Switch to clear cache
		mapView.mapType = .mutedStandard
		mapView.isRotateEnabled = true
		searchBar.delegate = self
		searchBar.searchTextField.clearButtonMode = .whileEditing
		
		//Tap anywhere to hide keyboard
		let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
		view.addGestureRecognizer(tap)
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		mapView.isRotateEnabled = true
		locationManager.startUpdatingLocation()
		fetchPhotoData()
		
		let currentMapCenterCoordinate = AppDelegate.get().getCurrentMapCenterCoordinate()
		let currentMapViewSpan = AppDelegate.get().getCurrentMapViewSpan()
		if viewFirstLoad {
			zoomToCurrentLocation()
			viewFirstLoad = false
		}
		else {
			zoomToCoordinate(coordinate: currentMapCenterCoordinate, span: currentMapViewSpan)
		}
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		locationManager.stopUpdatingLocation()
		AppDelegate.get().setCurrentMapCenterCoordinate(mapView.centerCoordinate)
		AppDelegate.get().setCurrentMapViewSpan(mapView.region.span)
	}
	
	private func zoomToCoordinate(coordinate: CLLocationCoordinate2D, span: MKCoordinateSpan) {
		let region = MKCoordinateRegion(center: coordinate, span: span)
		mapView.setRegion(region, animated: true)
	}
	
	private func zoomToCurrentLocation() {
		let coordinate = mapView.userLocation.coordinate
		let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
		let region = MKCoordinateRegion(center: coordinate, span: span)
		mapView.setRegion(region, animated: true)
	}
	
	@IBAction func addTapped(_ sender: Any) {
		openPhotoSelectSheet()
	}
	
	@IBAction func locationButtonTapped(_ sender: Any) {
		//Check location settings
		if (!locationManager.locationServicesEnabled() || !locationManager.locationUsageAllowed() || !locationManager.locationUsingBestAccuracy()) {
			showLocationAlert()
		}
		else {
			zoomToCurrentLocation()
		}
	}
	
	private func fetchPhotoData() {
		let currentMapCenterCoordinate = AppDelegate.get().getCurrentMapCenterCoordinate()
		let centerLocation = CLLocation(latitude: currentMapCenterCoordinate.latitude, longitude: currentMapCenterCoordinate.longitude)
		var fetchedPhotosArray: [CKRecord] = []
		
		let group = DispatchGroup()
		let predicate = NSPredicate(value: true)
		let query = CKQuery(recordType: "Photos", predicate: predicate)
		query.sortDescriptors = [CKLocationSortDescriptor(key: "location", relativeLocation: centerLocation)]
		
		group.enter()
		db.getSetAmountOfRecords(query: query, limit: 25) { returnedRecords in
			fetchedPhotosArray = returnedRecords
			group.leave()
		}
		
		group.notify(queue: .main) {
			self.photosArray = fetchedPhotosArray
			self.renderMapPins()
		}
	}
	
	//Places pins (markers) on map
	private func renderMapPins() {
		mapView.removeAnnotations(mapView.annotations)
		
		for photoRecord in photosArray {
			let location = photoRecord["location"] as! CLLocation
			let pin = MKPointAnnotation()
			pin.coordinate = location.coordinate
			pin.title = photoRecord.recordID.recordName
			
			mapView.addAnnotation(pin)
		}
	}
	
	//Shows alert giving information about using location and option to go to Settings or cancel
	private func showLocationAlert() {
		vibrate(style: .light)
		let alert = UIAlertController(title: "Precise location required", message: "Without precise location you will not be able to collect photos and earn XP", preferredStyle: .alert)
		
		let goToSettings = UIAlertAction(title: "Go to Settings", style: .default) { _ in
			guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
				self.showAlert(title: "Error", message: "Cannot open Settings app")
				return
			}
			if (UIApplication.shared.canOpenURL(settingsURL)) {
				UIApplication.shared.open(settingsURL)
			} else {
				self.showAlert(title: "Error", message: "Cannot open Settings app")
			}
		}
		
		let cancel = UIAlertAction(title: "Cancel", style: .default)
		
		alert.addAction(cancel)
		alert.addAction(goToSettings)
		self.present(alert, animated: true)
	}
	
	//Returns an asset of an image or nil if unsuccessful
	private func createPhotoAsset(_ image: UIImage) -> CKAsset? {
		//Set up photo url
		guard let data = image.pngData() else {
			return nil
		}
		//Hash image data to create unique url
		let imageHash = SHA256.hash(data: data)
		guard let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent(imageHash.description + ".png") else {
			return nil
		}
		
		//Save photo in device cache
		do {
			try data.write(to: url)
		} catch {
			return nil
		}
		
		let photoAsset = CKAsset(fileURL: url)
		return photoAsset
	}
	
	private func uploadPhoto(photoAsset: CKAsset, photoLocation: CLLocation) {
		let photoRecord = CKRecord(recordType: "Photos")
		photoRecord["authorID"] = AppDelegate.get().getCurrentUser()
		photoRecord["photo"] = photoAsset
		photoRecord["location"] = photoLocation
		photoRecord["collected"] = 0
		
		addButton.isHidden = true
		activityIndicator.startAnimating()
		
		self.db.saveRecord(record: photoRecord) { saved in
			DispatchQueue.main.async {
				if saved {
					self.showAlert(title: "Success", message: "Photo was uploaded")
				}
				else {
					self.showAlert(title: "Error while uploading photo", message: "Try again later")
				}
				self.activityIndicator.stopAnimating()
				self.addButton.isHidden = false
			}
		}
	}
	
	//Opens action sheet to choose image
	private func openPhotoSelectSheet() {
		uploadUsingCamera = false
		vibrate(style: .light)
		let alert = UIAlertController(title: "Upload a Photo", message: nil, preferredStyle: .actionSheet)
			alert.addAction(UIAlertAction(title: "Use Camera", style: .default, handler: { _ in
				if self.cameraPermissionGranted() {
					self.uploadUsingCamera = true
					self.openCamera()
				} else {
					self.requestCameraPermission()
				}
			}))
			alert.addAction(UIAlertAction(title: "Open Gallery", style: .default, handler: { _ in
				if self.galleryPermissionGranted() {
					self.openGallery()
				} else {
					self.requestGalleryPermission()
				}
			}))
			alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
			self.present(alert, animated: true, completion: nil)
	}
	
	//Returns a bool whether the user allowed camera access
	private func cameraPermissionGranted() -> Bool {
		if (AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized) {
			return true
		}
		else {
			return false
		}
	}
	
	//Returns a bool whether the user allowed gallery access
	private func galleryPermissionGranted() -> Bool {
		let status = PHPhotoLibrary.authorizationStatus()
		if (status == .authorized) {
			return true
		}
		else {
			return false
		}
	}
	
	//Asks user for camera permissions
	private func requestCameraPermission() {
		AVCaptureDevice.requestAccess(for: AVMediaType.video) { allowed in
			if !allowed {
				self.showPermissionAlert()
			}
		}
	}
	
	//Asks user for gallery permissions
	private func requestGalleryPermission() {
		PHPhotoLibrary.requestAuthorization({ status in
			if status != .authorized {
				self.showPermissionAlert()
			}
		})
	}
	
	//Shows alert regarding permissions
	private func showPermissionAlert() {
		vibrate(style: .light)
		let alert = UIAlertController(title: "Camera/Gallery permission required", message: "Without giving permission you cannot upload a photo", preferredStyle: .alert)
		
		let goToSettings = UIAlertAction(title: "Go to Settings", style: .default) { _ in
			guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
				self.showAlert(title: "Error", message: "Cannot open Settings app")
				return
			}
			if (UIApplication.shared.canOpenURL(settingsURL)) {
				UIApplication.shared.open(settingsURL)
			} else {
				self.showAlert(title: "Error", message: "Cannot open Settings app")
			}
		}
		
		let cancel = UIAlertAction(title: "Cancel", style: .default)
		
		alert.addAction(cancel)
		alert.addAction(goToSettings)
		self.present(alert, animated: true)
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

extension PhotosVC: UISearchBarDelegate {
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
	}
}

extension PhotosVC: MKMapViewDelegate {
	func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
		AppDelegate.get().setCurrentMapCenterCoordinate(mapView.centerCoordinate)
		AppDelegate.get().setCurrentMapViewSpan(mapView.region.span)
		
		fetchPhotoData()
	}
	
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		guard !(annotation is MKUserLocation) else {
			return nil
		}
		
		var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "mapAnnotation")
		if annotationView == nil {
			annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "mapAnnotation")
			annotationView?.canShowCallout = false
		}
		else {
			annotationView?.annotation = annotation
		}
		
		annotationView?.image = UIImage(named: "PhotoIcon")
		annotationView?.frame.size = CGSize(width: 25, height: 25)
		
		return annotationView
	}
}

extension PhotosVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	//Opens user's camera
	public func openCamera() {
		if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
			let imagePicker = UIImagePickerController()
			imagePicker.delegate = self
			imagePicker.sourceType = UIImagePickerController.SourceType.camera
			imagePicker.allowsEditing = false
			self.present(imagePicker, animated: true, completion: nil)
		}
		else
		{
			let alert  = UIAlertController(title: "Error", message: "There occured a problem while trying to open camera", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
			self.present(alert, animated: true, completion: nil)
		}
	}
	
	//Opens user's photo gallery
	public func openGallery() {
		if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
			let imagePicker = UIImagePickerController()
			imagePicker.delegate = self
			imagePicker.allowsEditing = false
			imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
			self.present(imagePicker, animated: true, completion: nil)
		}
		else
		{
			let alert  = UIAlertController(title: "Error", message: "There occured a problem while trying to open gallery", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
			self.present(alert, animated: true, completion: nil)
		}
	}
	
	//When user selects a photo from camera/gallery
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		var errorCreatingAsset = false
		var noLocationData = false
		
	imageSelection: if let selectedImage = info[.originalImage] as? UIImage {
		var photoLocation: CLLocation?
		if self.uploadUsingCamera {
			photoLocation = self.mapView.userLocation.location
		}
		else {
			guard let phPhotoAsset = info[.phAsset] as? PHAsset else {
				noLocationData = true
				break imageSelection
			}
			photoLocation = phPhotoAsset.location
		}
		if photoLocation == nil {
			noLocationData = true
			break imageSelection
		}
		
		//Create photo asset
		let photoAsset = self.createPhotoAsset(selectedImage)
		if photoAsset == nil {
			errorCreatingAsset = true
			break imageSelection
		}
		
		picker.dismiss(animated: true, completion: nil)
		self.uploadPhoto(photoAsset: photoAsset!, photoLocation: photoLocation!)
	}
	if noLocationData {
		picker.dismiss(animated: true, completion: nil)
		self.showAlert(title: "Cannot upload photo", message: "Photo must have a location inside its metadata")
	}
	else if errorCreatingAsset {
		picker.dismiss(animated: true, completion: nil)
		self.showAlert(title: "Error while uploading photo", message: "Try again later")
	}
	}
}
