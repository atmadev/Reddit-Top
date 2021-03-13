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
  
  private let username = "BeginningStand2574"
  private let password = "RedTop"
  private let clientID = "KfOzuW_XUbzJyA"
  private let secret = "hBPtda6RwnFj9F4AmU8urSB-cE6DUg"
  private let baseURLString = "https://oauth.reddit.com/"
  
  private let decoder = JSONDecoder()
  private let session = URLSession(configuration: .default)
  private var token: Token!
  var authorized: Bool { token != nil }
  
  private enum Method: String {
    case get = "GET"
    case post = "POST"
  }
  
  private enum Path: String {
    case top = "top"
  }
  
  init() {
    decoder.dateDecodingStrategy = .secondsSince1970
  }
  
  // MARK: Helpers
  
  private func request(for path: Path, method: Method, params: [String:String]? = nil) -> URLRequest {
    let paramString = params != nil ? ("?" + params!.urlParams) : ""
    
    let url = URL(string: baseURLString + path.rawValue + ".json" + paramString)!
    
    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    request.setValue(token.type + " " + token.access, forHTTPHeaderField: "Authorization")
    return request
  }
  
  private func run<T:Codable>(_ request: URLRequest,
                                 _ type: T.Type,
                              completed: @escaping (T) -> Void,
                                 failed: @escaping (Error) -> Void) {
    
    func handle(_ error: Error) { DispatchQueue.main.async { failed(error) } }
    
    let task = session.dataTask(with: request) { data, response, error in
      if let error = error {
        handle(error)
        return
      }
      
      guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode) else {
        
        handle(RedError(message: "Bad response"))
        return
      }
      
      if let mimeType = httpResponse.mimeType,
         mimeType == "application/json",
         let data = data {
        do {
          let result = try self.decoder.decode(type, from:data)
          DispatchQueue.main.async { completed(result) }
        }
        catch { handle(error) }
      }
      else { handle(RedError(message: "Response is not JSON")) }
    }
    task.resume()
  }
  
  func downloadData(at url: URL,
                 completed: @escaping (_ data:  Data)  -> Void,
                    failed: @escaping (_ error: Error) -> Void) {
    
    func handle(_ error: Error) { DispatchQueue.main.async { failed(error) } }
    
    let string = url.absoluteString.replacingOccurrences(of: "&amp;", with: "&")
    
    let escapedURL = URL(string: string)!
    
    let task = URLSession.shared.downloadTask(with: escapedURL) { location, response, error in
      
      if let error = error {
        handle(error)
        return
      }
      
      guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode) else {
        handle(RedError(message: "Bad response"))
        return
      }
      
      if let location = location {
        do {
          let data = try Data(contentsOf:location)
          DispatchQueue.main.async { completed(data) }
        }
        catch { handle(error) }
      }
    }
    task.resume()
  }
  
  // MARK: Service Methods
  
  func authorize(completed: @escaping () -> Void, failed: @escaping (Error) -> Void) {
    
    let url = URL(string: "https://ssl.reddit.com/api/v1/access_token")!
    var request = URLRequest(url: url)
    let params = "grant_type=password&username=" + username + "&password=" + password
    request.httpBody = params.data(using: .utf8)
    
    let basicAuthenticationChallenge = clientID + ":" + secret
    
    guard let data = basicAuthenticationChallenge.data(using: .utf8) else { return }
      let base64Str = data.base64EncodedString(options: .lineLength64Characters)
    
    request.setValue("Basic " + base64Str, forHTTPHeaderField: "Authorization")
    request.httpMethod = Method.post.rawValue
    
    run(request, Token.self, completed: { token in
      self.token = token
      completed()
    }, failed: failed)
  }
  
  func fetchTop(after: String? = nil,
            completed: @escaping (_ posts: [Post], _ after: String) -> Void,
               failed: @escaping (Error) -> Void) {
    
    let request = self.request(for: .top, method: .get, params: after != nil ? [ "after": after! ] : nil)
    
    run(request, Response.self, completed: { (response) in
      
        let posts = response.data.children.map{ Post(from: $0.data) }
        completed(posts, response.data.after)
      
    }, failed: failed)
  }
}
