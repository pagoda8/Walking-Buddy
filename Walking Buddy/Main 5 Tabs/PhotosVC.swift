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
	
	//Reference to location manager
	private let locationManager: LocationManager = LocationManager.shared
	
	//Used to show that photo is uploading
	private let activityIndicator = UIActivityIndicatorView(style: .medium)
	
	//Stores Photos records of photos to show on map
	private var photosArray: [CKRecord] = []
	
	//Reference to MapAPI class for location search
	private let mapAPI = MapAPI()
	
	//True if the user uses camera to upload a photo
	private var uploadUsingCamera = false
	
	//Indicates if the view loads for the first time
	private var viewFirstLoad = true
	
	@IBOutlet weak var searchBar: UISearchBar! //Search bar to find a location
	@IBOutlet weak var mapView: MKMapView! //Map view showing photo locations
	@IBOutlet weak var addButton: UIButton! //Button to add a photo
	
	// MARK: - View functions
	
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
		
		//Set up map view
		mapView.delegate = self
		mapView.mapType = .hybrid //Switch to clear cache
		mapView.mapType = .mutedStandard
		mapView.isRotateEnabled = true
		
		//Set up search bar
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
		
		//Zoom to user location only if it's a new app session
		let zoomToUserLocation = AppDelegate.get().getZoomToUserLocationBool()
		if zoomToUserLocation {
			zoomToCurrentLocation()
			AppDelegate.get().setZoomToUserLocationBool(false)
		}
		else {
			let currentMapCenterCoordinate = AppDelegate.get().getCurrentMapCenterCoordinate()
			let currentMapViewSpan = AppDelegate.get().getCurrentMapViewSpan()
			zoomToCoordinate(coordinate: currentMapCenterCoordinate, span: currentMapViewSpan)
		}
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		locationManager.stopUpdatingLocation()
		AppDelegate.get().setCurrentMapCenterCoordinate(mapView.centerCoordinate)
		AppDelegate.get().setCurrentMapViewSpan(mapView.region.span)
		
		if locationPermissionGranted() {
			AppDelegate.get().setRecentUserLocation(mapView.userLocation.coordinate)
		}
		else {
			AppDelegate.get().setRecentUserLocation(nil)
		}
	}
	
	// MARK: - IBActions
	
	//When (+) button is tapped
	@IBAction func addTapped(_ sender: Any) {
		openPhotoSelectSheet()
	}
	
	//When location button is tapped
	@IBAction func locationButtonTapped(_ sender: Any) {
		if locationPermissionGranted() {
			zoomToCurrentLocation()
		}
		else {
			showLocationAlert()
		}
	}
	
	// MARK: - Functions
	
	//Centers the map on a given coordinate and zooms with given span
	private func zoomToCoordinate(coordinate: CLLocationCoordinate2D, span: MKCoordinateSpan) {
		let region = MKCoordinateRegion(center: coordinate, span: span)
		mapView.setRegion(region, animated: false)
	}
	
	//Centers and zooms the map on user's current location
	private func zoomToCurrentLocation() {
		let coordinate = mapView.userLocation.coordinate
		let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
		let region = MKCoordinateRegion(center: coordinate, span: span)
		mapView.setRegion(region, animated: true)
	}
	
	//Fetches Photos records and renders pins on map
	private func fetchPhotoData() {
		let currentMapCenterCoordinate = AppDelegate.get().getCurrentMapCenterCoordinate()
		let centerLocation = CLLocation(latitude: currentMapCenterCoordinate.latitude, longitude: currentMapCenterCoordinate.longitude)
		var fetchedPhotosArray: [CKRecord] = []
		
		//Get 25 photos closest to user location
		let predicate = NSPredicate(value: true)
		let query = CKQuery(recordType: "Photos", predicate: predicate)
		query.sortDescriptors = [CKLocationSortDescriptor(key: "location", relativeLocation: centerLocation)]
		
		let group = DispatchGroup()
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
	
	//Places pins (annotations) on map
	private func renderMapPins() {
		mapView.removeAnnotations(mapView.annotations)
		
		for photoRecord in photosArray {
			let location = photoRecord["location"] as! CLLocation
			let pin = MKPointAnnotation()
			pin.coordinate = location.coordinate
			//Hold Photos record ID inside the pin
			pin.title = photoRecord.recordID.recordName
			
			mapView.addAnnotation(pin)
		}
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
	
	//Uploads a photo along with the location to db
	private func uploadPhoto(photoAsset: CKAsset, photoLocation: CLLocation) {
		let photoRecord = CKRecord(recordType: "Photos")
		photoRecord["authorID"] = AppDelegate.get().getCurrentUser()
		photoRecord["photo"] = photoAsset
		photoRecord["location"] = photoLocation
		photoRecord["collected"] = 0
		
		addButton.isHidden = true
		activityIndicator.startAnimating()
		
		self.db.saveRecord(record: photoRecord) { [weak self] saved in
			DispatchQueue.main.async {
				if saved {
					self?.showAlert(title: "Success", message: "Photo was uploaded")
				}
				else {
					self?.showAlert(title: "Error while uploading photo", message: "Try again later")
				}
				self?.activityIndicator.stopAnimating()
				self?.addButton.isHidden = false
			}
		}
	}
	
	// MARK: - Permission check functions
	
	//Returns true if the user's device location settings are properly set up
	private func locationPermissionGranted() -> Bool {
		if (!locationManager.locationServicesEnabled() || !locationManager.locationUsageAllowed() || !locationManager.locationUsingBestAccuracy()) {
			return false
		}
		else {
			return true
		}
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
	
	// MARK: - Permission request functions
	
	//Asks user for camera permissions
	private func requestCameraPermission() {
		AVCaptureDevice.requestAccess(for: AVMediaType.video) { [weak self] allowed in
			if !allowed {
				self?.showPermissionAlert()
			}
		}
	}
	
	//Asks user for gallery permissions
	private func requestGalleryPermission() {
		PHPhotoLibrary.requestAuthorization({ [weak self] authorizationState in
			if authorizationState != .authorized {
				self?.showPermissionAlert()
			}
		})
	}
	
	// MARK: - Custom alerts
	
	//Opens action sheet to choose photo
	private func openPhotoSelectSheet() {
		uploadUsingCamera = false
		vibrate(style: .light)
		let alert = UIAlertController(title: "Upload a Photo", message: nil, preferredStyle: .actionSheet)
			alert.addAction(UIAlertAction(title: "Use Camera", style: .default, handler: { [weak self] _ in
				if self?.cameraPermissionGranted() ?? false {
					//Check location settings before camera upload
					if self?.locationPermissionGranted() ?? false {
						self?.uploadUsingCamera = true
						self?.openCamera()
					}
					else {
						self?.showLocationAlert()
					}
				} else {
					self?.requestCameraPermission()
				}
			}))
			alert.addAction(UIAlertAction(title: "Open Gallery", style: .default, handler: { [weak self] _ in
				if self?.galleryPermissionGranted() ?? false {
					self?.openGallery()
				} else {
					self?.requestGalleryPermission()
				}
			}))
			alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
			self.present(alert, animated: true, completion: nil)
	}
	
	//Shows alert giving information about using location and option to go to Settings or cancel
	private func showLocationAlert() {
		vibrate(style: .light)
		let alert = UIAlertController(title: "Precise location required", message: "Without precise location you will not be able to collect photos and earn XP", preferredStyle: .alert)
		
		let goToSettings = UIAlertAction(title: "Go to Settings", style: .default) { [weak self] _ in
			guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
				self?.showAlert(title: "Error", message: "Cannot open Settings app")
				return
			}
			if (UIApplication.shared.canOpenURL(settingsURL)) {
				UIApplication.shared.open(settingsURL)
			} else {
				self?.showAlert(title: "Error", message: "Cannot open Settings app")
			}
		}
		let cancel = UIAlertAction(title: "Cancel", style: .default)
		
		alert.addAction(cancel)
		alert.addAction(goToSettings)
		self.present(alert, animated: true)
	}
	
	//Shows alert regarding camera/gallery permissions
	private func showPermissionAlert() {
		vibrate(style: .light)
		let alert = UIAlertController(title: "Camera/Gallery permission required", message: "Without giving permission you cannot upload a photo", preferredStyle: .alert)
		
		let goToSettings = UIAlertAction(title: "Go to Settings", style: .default) { [weak self] _ in
			guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
				self?.showAlert(title: "Error", message: "Cannot open Settings app")
				return
			}
			if (UIApplication.shared.canOpenURL(settingsURL)) {
				UIApplication.shared.open(settingsURL)
			} else {
				self?.showAlert(title: "Error", message: "Cannot open Settings app")
			}
		}
		let cancel = UIAlertAction(title: "Cancel", style: .default)
		
		alert.addAction(cancel)
		alert.addAction(goToSettings)
		self.present(alert, animated: true)
	}
	
	// MARK: - Other
	
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

// MARK: - Map view delegate functions

extension PhotosVC: MKMapViewDelegate {
	//When user taps on a map annotation
	func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
		guard !(annotation is MKUserLocation || annotation.title == nil) else {
			return
		}
		guard (annotation.title! != nil) else {
			return
		}

		AppDelegate.get().setPhotoToOpen(annotation.title!!)
		AppDelegate.get().setVCIDOfCaller("tabController")
		AppDelegate.get().setDesiredTabIndex(1)
		showVC(identifier: "photoDetails")
	}
	
	//When user moves the map
	func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
		//Don't save current coordinate and span on first load (prevents a bug)
		if viewFirstLoad {
			viewFirstLoad = false
		}
		else {
			AppDelegate.get().setCurrentMapCenterCoordinate(mapView.centerCoordinate)
			AppDelegate.get().setCurrentMapViewSpan(mapView.region.span)
		}
		
		fetchPhotoData()
	}
	
	//Creates and returns an annotation view
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

// MARK: - Image picker delegate functions

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
		else {
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
		else {
			let alert  = UIAlertController(title: "Error", message: "There occured a problem while trying to open gallery", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
			self.present(alert, animated: true, completion: nil)
		}
	}
	
	//When user selects a photo from camera/gallery
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		var errorCreatingAsset = false
		var noLocationData = false
		
		//Try to get photo's location and create the asset
	imageSelection: if let selectedImage = info[.originalImage] as? UIImage {
		var photoLocation: CLLocation?
		
		if self.uploadUsingCamera {
			photoLocation = self.mapView.userLocation.location
		}
		else {
			guard let phPhotoAsset = info[.phAsset] as? PHAsset else {
				//Unable to get photo's phAsset needed to get location
				noLocationData = true
				break imageSelection
			}
			photoLocation = phPhotoAsset.location
		}
		if photoLocation == nil {
			//Photo doesn't have location in metadata
			noLocationData = true
			break imageSelection
		}
		
		//Create photo asset
		let photoAsset = self.createPhotoAsset(selectedImage)
		if photoAsset == nil {
			//Unable to create asset
			errorCreatingAsset = true
			break imageSelection
		}
		
		//When asset and location is ready to be saved
		picker.dismiss(animated: true, completion: nil)
		self.uploadPhoto(photoAsset: photoAsset!, photoLocation: photoLocation!)
	}
	//When above code breaks (or finishes)
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

// MARK: - Search bar delegate functions

extension PhotosVC: UISearchBarDelegate {
	//When search button on keyboard is tapped
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		//Hide keyboard
		searchBar.resignFirstResponder()
		
		//Find location and zoom map
		if !(searchBar.text?.isEmpty ?? true) {
			self.mapAPI.getLocation(address: searchBar.text!) { [weak self] (coordinate, name) in
				DispatchQueue.main.async {
					if coordinate != nil {
						let mapViewSpan = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
						self?.zoomToCoordinate(coordinate: coordinate!, span: mapViewSpan)
					}
					else {
						self?.showAlert(title: "Error", message: "Could not find this location")
					}
				}
			}
		}
	}
}
