//
//  Endpoint.swift
//  GeenyGateway
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit

class Endpoint: NSObject {
  
  static var connectHost = "connect.geeny.io"
  static var connectBaseURL = "https://\(connectHost)"

  static var thingManagerHost = "labs.geeny.io"
  static var thingManagerBaseURL = "https://\(thingManagerHost)"

  static var mqttHost = "mqtt.geeny.io"

  static func connectURLString(path: String) -> String {
    return urlString(baseURL: connectBaseURL, path: path)
  }
  
  static func thingManagerURLString(path: String) -> String {
    return urlString(baseURL: thingManagerBaseURL, path: path)
  }
  
  private static func urlString(baseURL: String, path: String) -> String {
    if path.starts(with: "/") {
      return baseURL + path
    } else {
      return "\(baseURL)/\(path)"
    }
  }
  
}