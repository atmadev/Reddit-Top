//
//  TopListVC.swift
//  Reddit Top
//
//  Created by Alexander Koryttsev on 28.02.2021.
//

import UIKit

class TopListVC: UITableViewController {
  
  var posts: [Post] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    var inset = tableView.contentInset
    inset.top += 5
    inset.bottom += 5
    tableView.contentInset = inset
    
    API.shared.fetchTop {
      self.posts = $0
      self.tableView.reloadData()
    }
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return posts.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PostCell
    let post = posts[indexPath.row]
    
    cell.subredditLabel?.text = "r/" + post.subreddit
    cell.authorLabel?.text = (isHeightCompact ? "• Posted by " : "") + "u/" + post.author
    
    cell.hoursAgoLabel?.text = post.created.hoursAgo
    
    cell.commentsCountLabel?.text = post.commentsCount.thousands
   
    cell.titleLabel?.text = post.title
    cell.setPhotoResolution(post.image?.thumbnail)
  
    return cell
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    var height:CGFloat = 10 /*grey area insets*/ + 10 /* top inset */
    height += isHeightCompact ? 17 : 36 /* r/u/ labels stac k*/
    
    let post = posts[indexPath.row]
    let rect = post.title.boundingRect(with: .init(width: UIScreen.width - (isHeightCompact ? 48 : 28),
                                                   height: .greatestFiniteMagnitude),
                                       options: [.usesLineFragmentOrigin, .usesFontLeading],
                                       attributes: [.font: UIFont.boldSystemFont(ofSize: 17)], context: nil)
    height += rect.height + 16 /* title insets */
    
    height += PostCell.photoHeight(for: post.image?.thumbnail, traitCollection: traitCollection)
   
    height += 40 /* comments */
    height += 5 /* buffer */
    
    return ceil(height)
  }
  
  override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
    if let selectedRow = tableView.indexPathForSelectedRow {
      let post = posts[selectedRow.row]
      return post.image != nil
    }
    return false
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let selectedRow = tableView.indexPathForSelectedRow {
      let post = posts[selectedRow.row]
      let imageVC = segue.destination as! ImageVC
      imageVC.resolution = post.image!.source
    }
  }
  
  @IBAction func unwindToList(_ unwindSegue: UIStoryboardSegue) {}

  var lastVisibleIndexPath: IndexPath?
  var offsetK: CGFloat = 0
  
  override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
    super.willTransition(to: newCollection, with: coordinator)
    
    if let visibleRows = tableView.indexPathsForVisibleRows,
       visibleRows.count > 0 {
      
      let (_, maxVisibleIndexPath) = visibleRows.reduce((height:0, indexPath:visibleRows.first!)) { (maxHeight, indexPath) -> (CGFloat, IndexPath) in
        
        let intersection = self.tableView.rectForRow(at: indexPath).intersection(self.tableView.bounds)
        
        // TODO: figure why i can't use .height
        if intersection.height > maxHeight.0 {
          return (intersection.height, indexPath)
        }
        return maxHeight
      }
      
      lastVisibleIndexPath = maxVisibleIndexPath
      
    }
    
  }
  
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    
    tableView.reloadData()
    DispatchQueue.main.async {
      if let indexPath = self.lastVisibleIndexPath {
        self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
      }
    }
  }
  

}
