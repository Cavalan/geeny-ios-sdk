//
//  StringExtensions.swift
//  GeenyGateway
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit

extension String {
  
  // MARK: UUID
  
  private static let uuidGroupIndexes = [(0, 8), (8, 12), (12, 16), (16, 20), (20, 32)]
  
  /// Formats the string into 8-4-4-4-12 groups, like
  /// 123e4567-e89b-12d3-a456-426655440000.
  /// If the given string is has invalid length (!= 32), 
  /// the original string will be returned unmodified.
  func geenyUUIDFormatted() -> String {
    guard characters.count == 32 else {
      print("[WARN] Cannot format the string to UUID format because the string has invalid length \(characters.count), it should be 32 instead.")
      return self
    }
    
    var result = ""
    for group in String.uuidGroupIndexes {
      let fromIndex = index(startIndex, offsetBy: group.0)
      let toIndex = index(startIndex, offsetBy: group.1)
      let substring = String(self[fromIndex ..< toIndex])
      if !result.isEmpty {
        result.append("-")
      }
      result.append(substring)
    }
    return result
  }
  
}
