//
//  CustomProgressView.swift
//  Walking Buddy
//
//  Created by Wojtek on 16/02/2023.
//
//	Increases the progress view height

import Foundation
import UIKit

class CustomProgressView: UIProgressView {
	open override func layoutSubviews() {
		super.layoutSubviews()

		let maskLayerPath = UIBezierPath(roundedRect: bounds, cornerRadius: 4.0)
		let maskLayer = CAShapeLayer()
		maskLayer.frame = self.bounds
		maskLayer.path = maskLayerPath.cgPath
		layer.mask = maskLayer
	}
}
