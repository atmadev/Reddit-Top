//
//  API.swift
//  Reddit Top
//
//  Created by Alexander Koryttsev on 28.02.2021.
//

import Foundation
import UIKit


class API {
  static let shared = API()
  
  private let decoder = JSONDecoder()
  private let session = URLSession(configuration: .default, delegate: SessionDelegate.shared, delegateQueue: nil)
  
  init() {
    decoder.dateDecodingStrategy = .secondsSince1970
  }
  
  func authorize() {
    return
      let url = URL(string: "https://www.reddit.com/api/v1/access_token")! // TODO: make url constant
    var request = URLRequest(url: url)
    let bodyString = "grant_type=https://oauth.reddit.com/grants/installed_client&device_id=DO_NOT_TRACK_THIS_DEVICE"
    request.httpBody = bodyString.data(using: .utf8)
    print("body \(bodyString)")
      
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.setValue("Basic dnlEOGpQWTd5U1F0TXc6", forHTTPHeaderField: "Authorization")
    request.httpMethod = "POST"
    
      let task = URLSession.shared.dataTask(with: request) { data, response, error in
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
            
            print("response \(String(data: data, encoding: .utf8) ?? "")")
        }
      }
      task.resume()
  }
  
  func fetchTop(after: String, _ completion: @escaping (_ posts: [Post]) -> Void) {
    
      let url = URL(string: "https://www.oauth.reddit.com/top.json")! // TODO: make url constant
    
  var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer -9N5GdDl--UyzCYwYG_dnfIw8M_Tv1g", forHTTPHeaderField: "Authorization")
    
      let task = session.dataTask(with: request) { data, response, error in
        print("data: \(data != nil ? String(data:data!, encoding: .utf8) : "")\n response \(response)\nerror \(error)")
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
            
            print("response \(String(data: data, encoding: .utf8) ?? "")")
            
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


class SessionDelegate: NSObject, URLSessionDelegate {
  static let shared = SessionDelegate()
  
  func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

    let method = challenge.protectionSpace.authenticationMethod
            let host = challenge.protectionSpace.host

            switch (method, host) {
            case (NSURLAuthenticationMethodServerTrust, "www.oauth.reddit.com"):
                let trust = challenge.protectionSpace.serverTrust!
                let credential = URLCredential(trust: trust)
                completionHandler(.useCredential, credential)
            default:
                completionHandler(.performDefaultHandling, nil)
            }
    
  }
}
