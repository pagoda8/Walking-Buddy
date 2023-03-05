//
//  PhotosVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 30/01/2023.
//
//	Implements the Photos Tab View Controller

import UIKit

class PhotosVC: UIViewController {
	
	@IBOutlet weak var searchBar: UISearchBar!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		searchBar.delegate = self
		searchBar.searchTextField.clearButtonMode = .whileEditing
		
		//Tap anywhere to hide keyboard
		let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
		view.addGestureRecognizer(tap)
    }
	
	@IBAction func addTapped(_ sender: Any) {
		
	}

}

extension PhotosVC: UISearchBarDelegate {
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
	}
	
	
}
