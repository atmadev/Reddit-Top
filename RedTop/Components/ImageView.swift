//
//  ImageView.swift
//  Reddit Top
//
//  Created by Alexander Koryttsev on 28.02.2021.
//

import UIKit

// TODO: set this class for full screen image view
class ImageView: UIImageView {
  var imageResolution: ImageResolution? {
    didSet {
      if (oldValue?.url == imageResolution?.url) { return }
      
      image = nil
      guard let resolution = imageResolution else { return }
      
      API.shared.downloadData(at: resolution.url) { data in
        if resolution.url == self.imageResolution?.url {
          self.image = UIImage(data: data)
        }
      }
    }
  }
}
