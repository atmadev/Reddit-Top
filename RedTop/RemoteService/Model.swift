//
//  Model.swift
//  Reddit Top
//
//  Created by Alexander Koryttsev on 28.02.2021.
//

import Foundation
import UIKit


struct Token: Codable {
  let access: String
  let type: String
  
  enum CodingKeys: String, CodingKey {
    case access = "access_token"
    case type = "token_type"
  }
}

struct Response: Codable {
  let data: Data
  
  struct Data: Codable {
    let distance: Int
    let after: String
    let before: String?
    let children: [PostService]
    
    enum CodingKeys: String, CodingKey {
      case distance = "dist"
      case after
      case before
      case children
    }
  }
}

struct PostService: Codable {
  let data: Data
  
  struct Data: Codable {
    let id: String
    let title: String
    let created: Date
    let commentsCount: Int
    let subreddit: String
    let author: String
    let preview: Preview?
    
    enum CodingKeys: String, CodingKey {
      case id
      case title
      case created = "created_utc"
      case commentsCount = "num_comments"
      case subreddit
      case author
      case preview
    }
    
    struct Preview: Codable {
      let images: [Image]
      let enabled: Bool
      
      struct Image: Codable {
        let id: String
        let source: ImageResolution
        let resolutions: [ImageResolution]
      }
    }
  }
}

struct ImageResolution: Codable {
  let url: URL
  let width: Int
  let height: Int
  
  var k: CGFloat { CGFloat(width) / CGFloat(height) }
  
  var isPortrait: Bool { height > width }
}

struct Post: Codable {
  let id: String
  let title: String
  let created: Date
  let commentsCount: Int
  let subreddit: String
  let author: String
  let image: Image?
  
  struct Image: Codable {
    let thumbnail: ImageResolution
    let source: ImageResolution
  }
  
  init(from: PostService.Data) {
    self.id = from.id
    self.title = from.title
    self.created = from.created
    self.commentsCount = from.commentsCount
    self.subreddit = from.subreddit
    self.author = from.author
    
    if let preview = from.preview,
       preview.images.count > 0 {
      let image = preview.images.first!
      let thumbnail = image.resolutions.count > 4 ?
        image.resolutions[3] : // It is about 640 width
        image.resolutions.last!
      
      self.image = Image(thumbnail: thumbnail,
                         source: image.source)
    }
    else {
      self.image = nil
    }
  }
}
