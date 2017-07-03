//
//  KeychainStore.swift
//  GeenyGateway
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit
import KeychainSwift

class KeychainStore: NSObject {
  static let shared = KeychainStore()
  
  private struct Constants {
    static let keyAccessToken = "geeny-accessToken"
  }
  
  private let keychain = KeychainSwift()
  
  var accessToken: String? {
    get {
      return keychain.get(Constants.keyAccessToken)
    }
    set {
      if let newValue = newValue {
        keychain.set(newValue, forKey: Constants.keyAccessToken, withAccess: .accessibleAfterFirstUnlock)
      } else {
        keychain.delete(Constants.keyAccessToken)
      }
    }
  }
  
  func reset() {
    keychain.clear()
  }
}
