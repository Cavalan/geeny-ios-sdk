//
//  JSONSerializationExtensions.swift
//  GeenyGateway
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit

extension JSONSerialization {
  
  static func geenySimpleJSONObject(from data: Data) -> [String: Any]? {
    do {
      let json = try JSONSerialization.jsonObject(with: data, options: [])
      if let json = json as? [String: Any] {
        return json
      } else {
        return nil
      }
    } catch {
      return nil
    }
  }
  
  static func geenySimpleJSONObject(at path: String) -> [String: Any]? {
    let url = URL(fileURLWithPath: path)
    do {
      let data = try Data(contentsOf: url)
      return geenySimpleJSONObject(from: data)
    } catch let e {
      print("[WARN] Cannot read data from: \(path). Error: \(e)")
      return nil
    }
  }
  
  static func geenyStoreJSONObject(_ json: [String: Any], to path: String) -> Bool {
    do {
      let directory = (path as NSString).deletingLastPathComponent
      if !FileManager.default.fileExists(atPath: directory) {
        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
      }
      
      let data = try JSONSerialization.data(withJSONObject: json, options: [])
      let url = URL(fileURLWithPath: path)
      try data.write(to: url)
      return true
    } catch let e {
      print("[WARN] Cannot write data to: \(path). Error: \(e)")
      return false
    }
  }
  
}
