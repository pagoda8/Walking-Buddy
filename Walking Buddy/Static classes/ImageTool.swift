//
//  ImageTool.swift
//  Walking Buddy
//
//  Created by Wojtek on 03/04/2023.
//
//	Provides static operations on images

import Foundation
import UIKit

public class ImageTool {
	
	//Returns a downsampled UIImage
	//Taken from: https://swiftsenpai.com/development/reduce-uiimage-memory-footprint/
	public static func downsample(imageAt imageURL: URL, to pointSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
		
		// Create an CGImageSource that represent an image
		let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
		guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, imageSourceOptions) else {
			return nil
		}
		
		// Calculate the desired dimension
		let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
		
		// Perform downsampling
		let downsampleOptions = [
			kCGImageSourceCreateThumbnailFromImageAlways: true,
			kCGImageSourceShouldCacheImmediately: true,
			kCGImageSourceCreateThumbnailWithTransform: true,
			kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
		] as CFDictionary
		
		guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
			return nil
		}
		
		// Return the downsampled image as UIImage
		return UIImage(cgImage: downsampledImage)
	}
}
