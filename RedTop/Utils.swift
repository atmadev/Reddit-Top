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

class RedError: NSError {
  init(message: String) {
    super.init(domain: "redtop", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension Dictionary where Key == String, Value == String {
  var urlParams: String {
    map { "\($0)=\($1)" }.joined(separator: "&")
  }
}

extension Encodable {
  var json: Data {
    let encoder = JSONEncoder()
    return try! encoder.encode(self)
  }
}

extension Decodable {
  static func decode(from data: Data) -> Self {
    let decoder = JSONDecoder()
    return try! decoder.decode(Self.self, from: data)
  }
}

extension NSCoder {
  func decode<T>(_ type: T.Type, for key: String) throws -> T where T : Decodable {
    let data = self.decodeObject(forKey: key) as! Data
    return T.decode(from: data)
  }
}
