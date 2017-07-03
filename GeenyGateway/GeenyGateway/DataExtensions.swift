//
//  DataExtensions.swift
//  BLEServiceBrowser
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit

extension Data {
  /// Displays the data as a hex String, useful for debugging of BLE devices
  public func geenyHexEncodedString() -> String {
    return map { String(format: "%02hhx", $0) }.joined()
  }
  
  // 0x03 02 01 => 0x01 02 03
  func geenyEndiannessFlippedString(fromIndex from: Int, toInclusiveIndex to: Int, uppercased: Bool = true) -> String {
    let format: String
    if uppercased {
      format = "%02X"
    } else {
      format = "%02x"
    }
    
    var result = ""
    for i in (from...to).reversed() {
      let byte = self[i]
      let hex = String(format: format, byte)
      result += hex
    }
    return result
  }
  
}
