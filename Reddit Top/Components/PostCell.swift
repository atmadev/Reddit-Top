//
//  PostCell.swift
//  Reddit Top
//
//  Created by Alexander Koryttsev on 28.02.2021.
//

import UIKit

class PostCell: UITableViewCell {
  @IBOutlet var subredditLabel: UILabel!
  @IBOutlet var authorLabel: UILabel!
  @IBOutlet var commentsCountLabel: UILabel!
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet private var photoView: ImageView!
  @IBOutlet var hoursAgoLabel: UILabel!
  @IBOutlet var photoHeightConstraint: NSLayoutConstraint!
  
  func setPhotoResolution(_ resolution: ImageResolution?) {
    photoView?.imageResolution = resolution
    
    guard let resolution = resolution else {
      photoHeightConstraint.constant = 0
      return
    }
    
    photoHeightConstraint.constant = PostCell.photoHeight(for: resolution, traitCollection: traitCollection)
  }
  
  static func photoHeight(for resolution: ImageResolution?, traitCollection: UITraitCollection) -> CGFloat {
    
    guard let resolution = resolution else { return 0 }
    
    return ceil(traitCollection.isHeightCompact ? (UIScreen.height - 60) : (UIScreen.width / resolution.k + 5))
  }
}
