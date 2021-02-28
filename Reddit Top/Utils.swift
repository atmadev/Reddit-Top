//
//  Utils.swift
//  Reddit Top
//
//  Created by Alexander Koryttsev on 28.02.2021.
//

import Foundation

extension Date {
  var hoursAgo: String {
    let interval = Int(Date().timeIntervalSince(self))
    let hours = interval / 3600
    return "\(hours) hours ago"
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
