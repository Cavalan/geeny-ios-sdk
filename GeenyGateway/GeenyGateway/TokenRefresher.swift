//
//  TokenRefresher.swift
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

/// Refresh the existing JWT token with Geeny Connect.
class TokenRefresher: NSObject {
  
  struct Constants {
    static let path = "/auth/jwt/refresh"
    static let urlString = Endpoint.connectURLString(path: path)
  }
  
  private struct RefreshResponse: Codable {
    let token: String
  }
  
  private let disposeBag = DisposeBag()
  
  func refresh(oldToken: String) -> Observable<Token> {
    let body = [
      "token": oldToken
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
        let decoded = try JSONDecoder().decode(RefreshResponse.self, from: data)
        let token = decoded.token
        return Observable.just(token)
      } catch let e {
        print("[WARN] Couldn't parse login response: \(e)")
        return Observable.error(APIError.invalidJSON)
      }
    case 400:
      // Token can't be renewed, the user should be logged out.
      return Observable.error(APIError.invalidCredentials)
    default:
      return Observable.error(APIError.invalidCredentials)
    }
  }
  
}

