//
//  Utils.swift
//  Reddit Top
//
//  Created by Alexander Koryttsev on 28.02.2021.
//

import UIKit

extension Date {
  var hoursAgo: String {
    let interval = Int(Date().timeIntervalSince(self))
    let hours = interval / 3600
    return "\(hours) hour\(hours == 1 ? "" : "s") ago"
  }
}

extension Int {
  var thousands: String {
    if self < 1000 { return String(self) }
      
    let thousands = self / 1000
    let hundreds = (self - thousands * 1000) / 100
    
    var string = String(thousands)
    if hundreds > 0 { string += ".\(hundreds)" }
    string += "k"
    
    return string
  }
}

extension UITraitEnvironment {
  var isHeightCompact: Bool { traitCollection.isHeightCompact }
}

extension UITraitCollection {
  var isHeightCompact: Bool { verticalSizeClass == .compact }
}

extension UIScreen {
  static var width: CGFloat { main.bounds.width }
  static var height: CGFloat { main.bounds.height }
}
