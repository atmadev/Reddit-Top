//
//  ImageView.swift
//  Reddit Top
//
//  Created by Alexander Koryttsev on 28.02.2021.
//

import UIKit


class ImageView: UIImageView {
  private var imageResolution: ImageResolution?
  
  func set(imageResolution: ImageResolution?,
                 completed: (() -> Void)? = nil,
                    failed: ((Error) -> Void)? = nil) {
    
    if (self.imageResolution?.url == imageResolution?.url) { return }
  
    image = nil
    self.imageResolution = imageResolution
    guard let resolution = imageResolution else { return }
    
    API.shared.downloadData(at: resolution.url,
                     completed: { data in
      if resolution.url == self.imageResolution?.url {
        self.image = UIImage(data: data)
      }
      if let completed = completed { completed() }
    }, failed: { error in
      self.image = UIImage(systemName: "exclamationmark.triangle.fill")
      
      if let failed = failed { failed(error) }
    })
  }
}
