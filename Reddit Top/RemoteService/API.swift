//
//  API.swift
//  Reddit Top
//
//  Created by Alexander Koryttsev on 28.02.2021.
//

import Foundation

class API {
  static let shared = API()
  
  private let decoder = JSONDecoder()
  
  init() {
    decoder.dateDecodingStrategy = .secondsSince1970
  }
  
  func fetchTop(_ completion: @escaping (_ posts: [Post]) -> Void) {
      let url = URL(string: "https://www.reddit.com/top.json")! // TODO: make url constant
      let task = URLSession.shared.dataTask(with: url) { data, response, error in
          if let error = error {
              self.handleClientError(error)
              return
          }
          guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
              self.handleServerError(response)
              return
          }
          if let mimeType = httpResponse.mimeType, mimeType == "application/json",
              let data = data {
            
          do {
            let myResponse = try self.decoder.decode(Response.self, from:data)
            let posts = myResponse.data.children.map{ Post(from: $0.data) }
              DispatchQueue.main.async {
                completion(posts)
              }
          }
          catch {
            print(error)
          }
        }
      }
      task.resume()
  }
  
  func downloadData(at url: URL, _ completion: @escaping (_ data: Data) -> Void) {
    let string = url.absoluteString.replacingOccurrences(of: "&amp;", with: "&")
    
    let escapedURL = URL(string: string)!
    
    let task = URLSession.shared.downloadTask(with: escapedURL) { location, response, error in
      
      if let error = error {
        self.handleClientError(error)
        return
      }
      
      guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode) else {
        self.handleServerError(response)
        return
      }
      
      if let location = location {
        do {
          let data = try Data(contentsOf:location)
          
          DispatchQueue.main.async {
            completion(data)
          }
        }
        catch {
          print(error)
        }
      }
    }
    task.resume()
  }
  
  func handleClientError(_ error: Error) {
    print("client error \(error)")
  }
  
  func handleServerError(_ response: URLResponse?) {
    print("server error \(String(describing: response))")
    
  }
}
