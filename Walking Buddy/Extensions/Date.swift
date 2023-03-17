//
//  Date.swift
//  Walking Buddy
//
//  Created by Wojtek on 11/02/2023.
//
//	Date extension that enables subtracting dates

import Foundation

extension Date {

	static func - (lhs: Date, rhs: Date) -> TimeInterval {
		return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
	}
}
