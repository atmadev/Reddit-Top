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
  
  var resolution: ImageResolution!
  
  var newWidth:CGFloat = 0
  var newHeight:CGFloat = 0
  var isPortrait: Bool { view.frame.height * resolution.k < view.frame.width }
  
  func viewForZooming(in scrollView: UIScrollView) -> UIView? { return imageView }
  
  required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
 
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    updateLayout()
    
    API.shared.downloadData(at: resolution.url) { data in
      self.imageView.image = UIImage(data: data)
    }
  }
  
  func scrollViewDidZoom(_ scrollView: UIScrollView) {
    updateInset()
  }
  
  func updateInset() {
    var inset = UIEdgeInsets()

    if (isPortrait) {
      let gap = view.frame.width - newWidth * scrollView.zoomScale
      inset.left = gap > 0 ?  gap / 2 : 0
    }
    else {
      let gap = view.frame.height - newHeight * scrollView.zoomScale
      inset.top = gap > 0 ?  gap / 2 : 0
    }
    
    scrollView.contentInset = inset
  }
  
  func updateLayout() {
    newWidth = view.frame.width
    newHeight = view.frame.height
    
    if (isPortrait) {
      newWidth = newHeight * resolution.k
    }
    else {
      newHeight = newWidth / resolution.k
    }
    
    imageViewWidthConstraint.constant = newWidth
    imageViewHeightConstraint.constant = newHeight
    
    updateInset()
    
    view.layoutIfNeeded()
  }
  
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    updateLayout()
  }
  
  override var prefersStatusBarHidden: Bool { true }
}
