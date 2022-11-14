//
//  Colour.swift
//  Walking Buddy
//
//  Created by Wojtek on 14/11/2022.
//

import Foundation
import SwiftUI

extension Color {
	static let theme = ColorTheme()
}

struct ColorTheme {
	let accent = Color("AccentColour")
	let background = Color("BackgroundColour")
	let blue = Color("BlueColour")
	let secondaryText = Color("SecondaryTextColour")
}
