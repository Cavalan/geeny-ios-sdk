//
//  TokenFetcher.swift
//  GeenyGateway
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// Acquire the JWT token by logging in with Geeny Connect.
class TokenFetcher: NSObject {
  
  struct Constants {
    static let path = "/auth/login"
    static let urlString = Endpoint.connectURLString(path: path)
  }
  
  private struct LoginResponse: Codable {
    let token: String
  }
  
  private let disposeBag = DisposeBag()
  
  func fetchToken(username: String, password: String) -> Observable<Token> {
    let body = [
      "email": username,
      "password": password
    ]
    guard let request = URLRequest.geenyCreatePost(urlString: Constants.urlString, jsonBody: body) else {
      print("[WARN] Cannot create fetch token request")
      return Observable.error(APIError.invalidRequest)
    }
    
    return URLSession.shared.rx.response(request: request)
      .flatMap({ (result: (HTTPURLResponse, Data)) -> Observable<Token> in
        let (response, data) = result
        return self.transformResponse(httpResponse: response, data: data)
      })
  }
  
  private func transformResponse(httpResponse: HTTPURLResponse, data: Data) -> Observable<Token> {
    switch httpResponse.statusCode {
      case 200:
        do {
          let decoded = try JSONDecoder().decode(LoginResponse.self, from: data)
          let token = decoded.token
          return Observable.just(token)
        } catch let e {
          print("[WARN] Couldn't parse login response: \(e)")
          return Observable.error(APIError.invalidJSON)
        }
      default:
        return Observable.error(APIError.invalidCredentials)
    }
  }
  
}
