//
//  URLRequestExtensions.swift
//  GeenyGateway
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit

extension URLRequest {

  /// Creates a POST URLRequest with JSON body. The header fields `Content-Type` and `Accept`
  /// are automatically filled. If provided again in `header`, the given value
  /// will override the default value.
  static func geenyCreatePost(urlString: String, token: String? = nil, additionalHeader: [String: String]? = nil, jsonBody: [String: Any]? = nil) -> URLRequest? {
    guard let url = URL(string: urlString) else {
      print("[WARN] Invalid url: \(urlString)")
      return nil
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    // Header
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    if let token = token {
      request.setValue("JWT \(token)", forHTTPHeaderField: "Authorization")
    }

    if let additionalHeader = additionalHeader {
      for (key, value) in additionalHeader {
        request.setValue(value, forHTTPHeaderField: key)
      }
    }

    // Body
    if let jsonBody = jsonBody {
      guard let body = try? JSONSerialization.data(withJSONObject: jsonBody, options: []) else {
        print("[WARN] Invalid jsonBody: \(jsonBody)")
        return nil
      }
      request.httpBody = body
    }

    return request
  }

}
