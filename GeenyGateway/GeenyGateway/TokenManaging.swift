//
//  TokenManaging.swift
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

typealias Token = String

/// A protocol that the token manager objects should conform to. Such an object
/// acts as a proxy to obtain, store and retrieve the token. The reason why
/// this protocol exists is because there might be different ways to authenticate,
/// for example via REST or OAuth.
protocol TokenManaging {
  var hasToken: Bool { get }
  var token: String? { get }
  func login(username: String, password: String) -> Observable<Token>
  func refreshedToken() -> Observable<Token>
  func logout()
  func reset()
}
