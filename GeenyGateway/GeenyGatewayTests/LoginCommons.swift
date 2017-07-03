//
//  LoginCommons.swift
//  GeenyGatewayTests
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit
import OHHTTPStubs
@testable import GeenyGateway

struct LoginCommons {
  static let validUsername = "good@user.name"
  static let validPassword = "goodpassword"
  
  static let invalidUsername = "bad@user.name"
  static let invalidPassword = "badpassword"
  
  static let response200Filename = "post-login-200.json"
  static let response400Filename = "post-login-400.json"
  
  static func postLoginCondition() -> OHHTTPStubsTestBlock {
    return isMethodPOST() && isHost(Endpoint.connectHost) && isPath(TokenFetcher.Constants.path)
  }
}
