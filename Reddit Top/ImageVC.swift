//
//  ImageVC.swift
//  Reddit Top
//
//  Created by Alexander Koryttsev on 28.02.2021.
//

import UIKit

class ImageVC: UIViewController, UIScrollViewDelegate {
  @IBOutlet var scrollView: UIScrollView!
  @IBOutlet var imageView: UIImageView!
  
  @IBOutlet var imageViewWidthConstraint: NSLayoutConstraint!
  @IBOutlet var imageViewHeightConstraint: NSLayoutConstraint!
  
  var resolution: ImageResolution?
  
  var newWidth:CGFloat = 0
  var newHeight:CGFloat = 0
  
  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
      return imageView
  }
  
  required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
  }
 
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    guard let resolution = resolution else {
      return
    }
    
    newWidth = view.frame.width
    newHeight = view.frame.height
    
    if (resolution.isPortrait) {
      newWidth = newHeight * resolution.k
    }
    else {
      newHeight = newWidth / resolution.k
    }
    
    imageViewWidthConstraint.constant = newWidth
    imageViewHeightConstraint.constant = newHeight
    
    updateInset()
    
    view.layoutIfNeeded()
    
    API.shared.downloadData(at: resolution.url) { data in
      self.imageView.image = UIImage(data: data)
    }
  }
  
  func scrollViewDidZoom(_ scrollView: UIScrollView) {
    updateInset()
  }
  
  func updateInset() {
    var inset = scrollView.contentInset
    inset.top = (view.frame.height - newHeight) / 2
    scrollView.contentInset = inset
  }
}
