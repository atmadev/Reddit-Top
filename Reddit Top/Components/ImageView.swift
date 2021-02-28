//
//  ImageView.swift
//  Reddit Top
//
//  Created by Alexander Koryttsev on 28.02.2021.
//

import UIKit

class ImageView: UIImageView {
  @IBOutlet var heightConstraint: NSLayoutConstraint?
  
  var imageResolution: ImageResolution? {
    didSet {
      self.image = nil
      guard imageResolution != nil else {
        heightConstraint?.constant = 0
        return
      }
      
      heightConstraint?.constant = CGFloat(imageResolution!.height) / 1.8
      let downloadingResolution = imageResolution
      API.shared.downloadData(at: imageResolution!.url) { data in
        if downloadingResolution?.url == self.imageResolution?.url {
          self.image = UIImage(data: data)
        }
      }
    }
  }
}
