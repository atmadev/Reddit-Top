//
//  ImageVC.swift
//  Reddit Top
//
//  Created by Alexander Koryttsev on 28.02.2021.
//

import UIKit

class ImageVC: UIViewController, UIScrollViewDelegate {
  
  @IBOutlet var scrollView: UIScrollView!
  @IBOutlet var imageView: ImageView!
  
  @IBOutlet var imageViewWidthConstraint: NSLayoutConstraint!
  @IBOutlet var imageViewHeightConstraint: NSLayoutConstraint!
  
  @IBOutlet var topBarTopInset: NSLayoutConstraint!
  @IBOutlet var topBarBackground: UIView!
  @IBOutlet var topBar: UIView!
  @IBOutlet var saveButton: UIButton!
  @IBOutlet var titleLabel: UILabel!
  
  @IBOutlet var activityIndicator: UIActivityIndicatorView!
  
  var resolution: ImageResolution!
  
  var normalizedWidth:CGFloat = 0
  var normalizedHeight:CGFloat = 0
  var isPortrait: Bool { view.frame.height * resolution.k < view.frame.width }
  
  func viewForZooming(in scrollView: UIScrollView) -> UIView? { return imageView }
  
  required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
  
  // MARK: View Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    topBarTopInset.constant = UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
  }
 
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    titleLabel.text = title
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    updateLayout()
    
    imageView.set(imageResolution: resolution, completed: {
      self.saveButton.isEnabled = true
      self.activityIndicator.stopAnimating()
    }, failed: { error in
      self.show(error: error)
      self.activityIndicator.stopAnimating()
    })
  }
  
  // MARK: Actions
  
  @IBAction func handle(pan: UIPanGestureRecognizer) {
    let window = view!.window
    let tranlsationY = pan.translation(in: window).y
    
    switch pan.state {
    case .began, .changed:
      if tranlsationY >= 0 {
        view.transform = .init(translationX: 0, y: tranlsationY)
      }
    case .ended, .cancelled:
      let velocityY = pan.velocity(in: view?.window).y
      if velocityY >= 0,
        (tranlsationY > 100 || velocityY > 700) {
        dismiss(animated: true, completion: nil)
      } else {
        var initialVelocity:CGFloat = 0
        if velocityY < 0 {
          let absVelocity = CGFloat(fabsf(Float(velocityY)))
          initialVelocity = absVelocity < tranlsationY ? absVelocity / tranlsationY : 1
        }
        
        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: initialVelocity,
                       options: []) {
          self.view.transform = .identity
        }
      }
    case .failed, .possible:
      break
    @unknown default:
      break
    }
  }
  
  @IBAction func saveToGallery(_ sender: UIBarButtonItem) {
    guard let image = imageView.image else { return }
    UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
  }
  
  @IBAction func toggleTopBar(_ sender: UITapGestureRecognizer) {
    UIView.transition(with: self.view,
                  duration: 0.25,
                  options: [.transitionCrossDissolve]) {
      self.topBar.isHidden = !self.topBar.isHidden
      self.topBarBackground.isHidden = self.topBar.isHidden
    }
  }
  
  @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
    if let error = error {
      let alert = UIAlertController(title: "❌  Error", message: error.localizedDescription, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default))
      present(alert, animated: true)
    } else {
      let alert = UIAlertController(title: "✅  Saved", message: nil, preferredStyle: .alert)
      present(alert, animated: true) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
          alert.dismiss(animated: true)
        }
      }
    }
  }
  
  // MARK: Layout
  
  func scrollViewDidZoom(_ scrollView: UIScrollView) { updateInset() }
  
  func updateInset() {
    var inset = UIEdgeInsets()

    if (isPortrait) {
      let gap = view.frame.width - normalizedWidth * scrollView.zoomScale
      inset.left = gap > 0 ? gap / 2 : 0
    }
    else {
      let gap = view.frame.height - normalizedHeight * scrollView.zoomScale
      inset.top = gap > 0 ? gap / 2 : 0
    }
    
    scrollView.contentInset = inset
  }
  
  func updateLayout() {
    normalizedWidth = view.frame.width
    normalizedHeight = view.frame.height
    
    if (isPortrait) { normalizedWidth  = normalizedHeight * resolution.k }
    else            { normalizedHeight = normalizedWidth  / resolution.k }
    
    imageViewWidthConstraint.constant = normalizedWidth
    imageViewHeightConstraint.constant = normalizedHeight
    
    updateInset()
    
    view.layoutIfNeeded()
  }
  
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    updateLayout()
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
