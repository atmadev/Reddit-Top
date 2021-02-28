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
    cell.authorLabel?.text = "u/" + post.author + " • " + post.created.hoursAgo
    
    cell.commentsCountLabel?.text = post.commentsCount.thousands
   
    cell.titleLabel?.text = post.title
    cell.photoView?.imageResolution = post.image?.thumbnail
  
    return cell
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let selectedRow = tableView.indexPathForSelectedRow {
      let post = posts[selectedRow.row]
      let imageVC = segue.destination as! ImageVC
      imageVC.resolution = post.image!.source
    }
  }
  

}
