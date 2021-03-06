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
  
  func authorize(completion: @escaping (_ success: Bool) -> Void) {
    let url = URL(string: "https://ssl.reddit.com/api/v1/access_token")! // TODO: make url constant
    var request = URLRequest(url: url)
    let params = "grant_type=password&username=" + username + "&password=" + password
    request.httpBody = params.data(using: .utf8)
    
    let basicAuthenticationChallenge = clientID + ":" + secret
    
    guard let data = basicAuthenticationChallenge.data(using: .utf8) else { return }
      let base64Str = data.base64EncodedString(options: .lineLength64Characters)
    
    request.setValue("Basic " + base64Str, forHTTPHeaderField: "Authorization")
    request.httpMethod = Method.post.rawValue
    
    run(request, type: Token.self) { (token) in
      self.token = token
      completion(true)
    } failed: { (error) in
      completion(false)
    }
  }
  
  private func request(for path: Path, method: Method) -> URLRequest {
    let url = URL(string: baseURLString + path.rawValue + ".json")!
    
    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    request.setValue(token.type + " " + token.access, forHTTPHeaderField: "Authorization")
    return request
  }
  
  private func run<T:Codable>(_ request: URLRequest, type: T.Type, completed: @escaping (T) -> Void, failed: @escaping (Error) -> Void) {
    let task = session.dataTask(with: request) { data, response, error in
        if let error = error {
          self.handleClientError(error)
          failed(error)
          return
        }
      
        guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode) else {
            self.handleServerError(response)
          failed(RedError(message: "Bad response"))
          return
        }
      
        if let mimeType = httpResponse.mimeType, mimeType == "application/json",
            let data = data {
          do {
            let result = try self.decoder.decode(type, from:data)
            
           completed(result)
          }
          catch {
            print(error)
            failed(error)
          }
        }
        else {
          failed(RedError(message: "Response is not JSON"))
        }
    }
    task.resume()
  }
  
  func fetchTop(after: String, _ completion: @escaping (_ posts: [Post]) -> Void) {
    let request = self.request(for: .top, method: .get)
    
    run(request, type:Response.self) { (response) in
        let posts = response.data.children.map{ Post(from: $0.data) }
        DispatchQueue.main.async {
          completion(posts)
        }
     
    } failed: { (error) in
      //TODO: handle error
    }
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
