//
//  Math.swift
//  AppKit
//
//  Created by Nicholas Bosak on 10/4/16.
//

import Foundation

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi / 180 }
    var radiansToDegress: Double { return Double(self) * 180 / .pi }
}

extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegress: Self { return self * 180 / .pi }
}
