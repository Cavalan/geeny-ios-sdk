//
//  GeenyURLSession.swift
//  GeenyGateway
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit

extension URLSession {
  
  static var geeny: URLSession = {
    let configuration = URLSessionConfiguration.default
    let session = URLSession(configuration: configuration)
    return session
  }()
  
}
