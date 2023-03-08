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

class PhotosVC: UIViewController {
	
	//Reference to db manager
	private let db = DBManager.shared
	
	//True if it is the first time the view is shown
	private var viewFirstLoad = true
	
	@IBOutlet weak var searchBar: UISearchBar!
	@IBOutlet weak var mapView: MKMapView!
	
	private var photosArray: [CKRecord] = []
	
	private let locationManager: LocationManager = LocationManager.shared
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
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
		db.getSetAmountOfRecords(query: query, limit: 50) { returnedRecords in
			fetchedPhotosArray = returnedRecords
			group.leave()
		}
		
		group.notify(queue: .main) {
			self.photosArray = fetchedPhotosArray
			self.renderMapPins()
		}
	}
	
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
