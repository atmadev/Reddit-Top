//
//  TopListVC.swift
//  Reddit Top
//
//  Created by Alexander Koryttsev on 28.02.2021.
//

import UIKit

class TopListVC: UITableViewController {
  
  var posts: [Post] = []
  
  var lastPost: Post? { posts.count > 0 ? posts[posts.count - 1] : nil }
  var lastFetchedID = ""
  var after = ""
  
  override func viewDidLoad() {
    super.viewDidLoad()
    var inset = tableView.contentInset
    inset.top += 5
    inset.bottom += 5
    tableView.contentInset = inset
    
    API.shared.authorize { (success) in
      if success { self.fetch() }
      
      self.refreshControl = UIRefreshControl()
      self.refreshControl?.addTarget(self, action: #selector(self.refresh), for: .valueChanged)
    }
  }
  
  func fetch(after: String? = nil, completion: @escaping () -> Void = {}) {
    API.shared.fetchTop(after:after) { (posts, nextAfter) in
      if after == nil {
        self.posts = posts
      }
      else {
        self.posts.append(contentsOf: posts)
      }
      self.after = nextAfter
      self.tableView.reloadData()
      completion()
    }
  }
  
  @objc func refresh() {
    fetch { self.refreshControl?.endRefreshing() }
  }
  
  // MARK: Table View Protocol
  
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
  
  override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    if posts.count - indexPath.row < 5 && lastFetchedID != lastPost!.id {
      print("fetch after " + lastPost!.id)
      lastFetchedID = lastPost!.id
      
      fetch(after: after)
    }
  }
  
  // MARK: Segues
  
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
      imageVC.title = "r/" + post.subreddit
    }
  }
  
  @IBAction func unwindToList(_ unwindSegue: UIStoryboardSegue) {}

  // MARK: Trait Collections
  
  var lastVisibleIndexPath: IndexPath?
  
  override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
    super.willTransition(to: newCollection, with: coordinator)
    
    if let visibleRows = tableView.indexPathsForVisibleRows,
       visibleRows.count > 0 {
      
      let (_, maxVisibleIndexPath) = visibleRows.reduce((maxHeightValue:0, maxHeightIndexPath:visibleRows.first!)) { (maxHeight, indexPath) -> (CGFloat, IndexPath) in
        
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
