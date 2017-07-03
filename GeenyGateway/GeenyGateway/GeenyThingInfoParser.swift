//
//  GeenyThingInfoParser.swift
//  GeenyGateway
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import Foundation

class GeenyThingInfoParser: NSObject {
  
  /// Parse the data received from the Geeny-BLE characteristic.
  static func parseData(_ value: Data) -> GeenyThingInfo? {
    guard value.count >= 2 else {
      print("[WARN] Value data has invalid length: \(value.count)")
      return nil
    }
    
    let version = parseVersion(byte0: value[0], byte1: value[1])
    switch version {
    case 1:
      return parseVersion1Data(value)
    default:
      print("[WARN] Unsupported version: \(version)")
      return nil
    }
  }
  
  static private func parseVersion(byte0: UInt8, byte1: UInt8) -> UInt {
    // Geeny firmeware sends data in little endian order.
    return UInt(byte1) << 8 + UInt(byte0)
  }
  
  static private func parseVersion1Data(_ value: Data) -> GeenyThingInfo? {
    guard value.count == 34 else {
      print("[WARN] Value data has invalid length: \(value.count)")
      return nil
    }
    
    let serialNumber = value.geenyEndiannessFlippedString(fromIndex: 2, toInclusiveIndex: 17).geenyUUIDFormatted()
    let thingType = value.geenyEndiannessFlippedString(fromIndex: 18, toInclusiveIndex: 33).geenyUUIDFormatted()
    return GeenyThingInfo(protocolVersion: 1, serialNumber: serialNumber, thingType: thingType)
  }

}
