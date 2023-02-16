//
//  Colour.swift
//  Walking Buddy
//
//  Created by Wojtek on 14/11/2022.
//
//	Holds references to colours

import Foundation
import SwiftUI

extension UIColor {
	static let theme = ColorTheme()
}

struct ColorTheme {
	let accent = UIColor(Color("AccentColour"))
	let accentOrange = UIColor(Color("AccentOrangeColour"))
	let background = UIColor(Color("BackgroundColour"))
	let blue = UIColor(Color("BlueColour"))
	let secondaryText = UIColor(Color("SecondaryTextColour"))
}
