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
  
  @IBOutlet var topBarBackground: UIView!
  @IBOutlet var topBar: UIView!
  @IBOutlet var saveButton: UIButton!
  @IBOutlet var titleLabel: UILabel!
  
  var resolution: ImageResolution!
  
  var newWidth:CGFloat = 0
  var newHeight:CGFloat = 0
  var isPortrait: Bool { view.frame.height * resolution.k < view.frame.width }
  
  func viewForZooming(in scrollView: UIScrollView) -> UIView? { return imageView }
  
  required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
 
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    titleLabel.text = title
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    updateLayout()
    
    API.shared.downloadData(at: resolution.url) { data in
      self.imageView.image = UIImage(data: data)
      self.saveButton.isEnabled = true
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
  
  @IBAction func saveToGallery(_ sender: UIBarButtonItem) {
    guard let image = imageView.image else { return }
    UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
  }

  @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
         if let error = error {
             // we got back an error!
             let ac = UIAlertController(title: "❌  Error", message: error.localizedDescription, preferredStyle: .alert)
             ac.addAction(UIAlertAction(title: "OK", style: .default))
             present(ac, animated: true)
         } else {
            let ac = UIAlertController(title: "✅  Saved", message: nil, preferredStyle: .alert)
          present(ac, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
              ac.dismiss(animated: true)
            }
          }
         }
     }
  
  @IBAction func toggleTopBar(_ sender: UITapGestureRecognizer) {
    UIView.transition(with: self.view,
                      duration: 0.25
                      , options: [.transitionCrossDissolve]) {
      self.topBar.isHidden = !self.topBar.isHidden
      self.topBarBackground.isHidden = self.topBar.isHidden
    }
  }
  
  //MARK: State preservation
  
  override func encodeRestorableState(with coder: NSCoder) {
    super.encodeRestorableState(with: coder)
    
    coder.encode(title, forKey: "Title")
    coder.encode(resolution.json, forKey: "Resolution")
  }
  
  override func decodeRestorableState(with coder: NSCoder) {
    super.decodeRestorableState(with: coder)
    
    title = coder.decodeObject(forKey: "Title") as? String
    resolution = try! coder.decode(ImageResolution.self, for: "Resolution")
  }
}
