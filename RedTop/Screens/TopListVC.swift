//
//  TopListVC.swift
//  Reddit Top
//
//  Created by Alexander Koryttsev on 28.02.2021.
//

import UIKit

class TopListVC: UITableViewController {
  var state = State()
  
  struct State: Codable {
    var posts: [Post] = []
    var lastFetchedID = ""
    var after = ""
    var restoredPostID: String?
    
    var lastPost: Post? { posts.count > 0 ? posts[posts.count - 1] : nil }
  }
  
  var newPosts: [Post]?
  
  // MARK: View Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    var inset = tableView.contentInset
    inset.top += 5
    inset.bottom += 5
    tableView.contentInset = inset
    
    API.shared.authorize(completed: {
      API.shared.fetchTop(completed: { (posts, nextAfter) in
        if self.state.posts.count > 0 {
          if posts.count > 0,
            self.state.posts.first!.id != posts.first!.id {
            self.newPosts = posts
            self.showNewPostsButton()
          }
        }
        else {
          self.state.posts = posts
          self.tableView.reloadData()
        }
      }, failed: self.show(error:))
     
      self.refreshControl = UIRefreshControl()
      self.refreshControl?.addTarget(self, action: #selector(self.refresh), for: .valueChanged)
          
    }, failed: show(error:))
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    scrollToRestoredPostIfNeeded()
  }
  
  // MARK: Actions

  func showNewPostsButton() {
    let button = UIButton(type: .system)
    button.setTitle(" Show New Posts", for: .normal)
    button.setImage(UIImage(systemName: "newspaper"), for: .normal)
    button.addTarget(self, action: #selector(showNewPosts), for: .touchUpInside)
    navigationItem.titleView = button
  }
  
  @objc
  func showNewPosts() {
    state = State()
    state.posts = newPosts!
    newPosts = nil
    tableView.reloadData()
    navigationItem.titleView = nil
    tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
  }
  
  func fetch(after: String? = nil, completion: @escaping () -> Void = {}) {
    API.shared.fetchTop(after:after, completed: { (posts, nextAfter) in
      if after == nil {
        self.state.posts = posts
      }
      else {
        self.state.posts.append(contentsOf: posts)
      }
      self.state.after = nextAfter
      self.tableView.reloadData()
      completion()
    }, failed: { error in
      self.show(error: error)
      completion()
    })
  }
  
  @objc func refresh() {
    navigationItem.titleView = nil
    fetch { self.refreshControl?.endRefreshing() }
  }
  
  // MARK: Table View Protocol
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return state.posts.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PostCell
    let post = state.posts[indexPath.row]
    
    cell.subredditLabel?.text = "r/" + post.subreddit
    cell.authorLabel?.text = (isHeightCompact ? "• Posted by " : "") + "u/" + post.author
    
    cell.hoursAgoLabel?.text = post.created.hoursAgo
    
    cell.commentsCountLabel?.text = post.commentsCount.thousands
   
    cell.titleLabel?.text = post.title
    cell.setPhotoResolution(post.image?.thumbnail)
  
    return cell
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    // automaticDimension using triggers unpredictible layout bugs
    // so, for reliable layout it is better to use oldschool manual cell height calculation
    
    var height:CGFloat = 10 /*grey area insets*/ + 10 /* top inset */
    height += isHeightCompact ? 17 : 36 /* r/u/ labels stac k*/
    
    let post = state.posts[indexPath.row]
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
    
    // Prevent calls on state restoring before authentication
    guard API.shared.authorized else { return }
    
    if state.posts.count - indexPath.row < 5 && state.lastFetchedID != state.lastPost!.id {
      state.lastFetchedID = state.lastPost!.id
      
      fetch(after: state.after)
    }
  }
  
  // MARK: Segues
  
  override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
    if let selectedRow = tableView.indexPathForSelectedRow {
      let post = state.posts[selectedRow.row]
      return post.image != nil
    }
    return false
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let selectedRow = tableView.indexPathForSelectedRow {
      let post = state.posts[selectedRow.row]
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
    lastVisibleIndexPath = mostVisibleIndexPath
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
  
  //MARK: State preservation
  
  override func encodeRestorableState(with coder: NSCoder) {
    super.encodeRestorableState(with: coder)
    
    if let indexPath = mostVisibleIndexPath,
       state.posts.count > 0 {
      
      let post = state.posts[indexPath.row]
      state.restoredPostID = post.id
    }
    
    coder.encode(state.json, forKey: "State")
  }
  
  override func decodeRestorableState(with coder: NSCoder) {
    super.decodeRestorableState(with: coder)
    
    state = try! coder.decode(State.self, for: "State")
  }
  
  func scrollToRestoredPostIfNeeded() {
    if let postID = state.restoredPostID,
       state.posts.count > 0,
       let index = state.posts.firstIndex(where: { $0.id == postID }) {
      
      tableView.scrollToRow(at: .init(row: index, section: 0),
                            at: .top,
                            animated: false)
      state.restoredPostID = nil
    }
  }
  
  var mostVisibleIndexPath: IndexPath? {
    if let visibleRows = tableView.indexPathsForVisibleRows,
       visibleRows.count > 0 {
      
      let (_, maxVisibleIndexPath) = visibleRows.reduce((maxHeightValue:0, maxHeightIndexPath:visibleRows.first!)) { (maxHeight, indexPath) -> (CGFloat, IndexPath) in
        
        let intersection = self.tableView.rectForRow(at: indexPath).intersection(self.tableView.bounds)
        
        if intersection.height > maxHeight.0 {
          return (intersection.height, indexPath)
        }
        return maxHeight
      }
      
      return maxVisibleIndexPath
    }
    
    return nil
  }
}
