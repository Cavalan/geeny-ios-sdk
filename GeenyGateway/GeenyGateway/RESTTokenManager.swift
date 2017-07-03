//
//  RESTTokenManager.swift
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

public typealias LoginResultBlock = (Result<Bool>)->()

class RESTTokenManager: NSObject, TokenManaging {
  static let shared = RESTTokenManager()

  var token: String? = KeychainStore.shared.accessToken
  var hasToken: Bool {
    return token != nil
  }

  private let tokenFetcher = TokenFetcher()
  private let tokenRefresher = TokenRefresher()
  private let disposeBag = DisposeBag()

  func login(username: String, password: String) -> Observable<Token> {
    return tokenFetcher.fetchToken(username: username, password: password)
      .map { token -> Token in
        self.token = token
        KeychainStore.shared.accessToken = token
        return token
      }
  }
  
  func refreshedToken() -> Observable<Token> {
    guard let oldToken = token else {
      return Observable.error(APIError.noCredentials)
    }
    return tokenRefresher.refresh(oldToken: oldToken)
  }
  
  func logout() {
    token = nil
    KeychainStore.shared.accessToken = nil
  }
  
  func reset() {
    KeychainStore.shared.reset()
    token = nil
  }
  
}
