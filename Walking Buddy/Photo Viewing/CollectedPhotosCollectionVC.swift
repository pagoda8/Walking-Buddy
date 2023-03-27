//
//  CollectedPhotosCollectionVC.swift
//  Walking Buddy
//
//  Created by Wojtek on 27/03/2023.
//
//	Defines a collection view cell in the collected photos VC

import UIKit

class CollectedPhotosCollectionVC: UICollectionViewCell {

	@IBOutlet weak var imageView: UIImageView!

	override func awakeFromNib() {
		super.awakeFromNib()
		// Initialization code
	}
	
	//Sets the image for a cell
	public func configure(with image: UIImage) {
		imageView.image = image
	}

	static func nib() -> UINib {
		return UINib(nibName: "CollectedPhotosCollectionVC", bundle: nil)
	}
}
