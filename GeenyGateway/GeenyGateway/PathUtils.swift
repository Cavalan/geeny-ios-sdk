//
//  PathUtils.swift
//  GeenyGateway
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit

class PathUtils {
  
  static func documentsFolderPath() -> String {
    return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
  }
  
  static func pathInDocumentsFolder(components: [String]?) -> String {
    let result = documentsFolderPath()
    if let components = components {
      var nsResult = (result as NSString)
      for component in components {
        nsResult = (nsResult.appendingPathComponent(component) as NSString)
      }
      return (nsResult as String)
    } else {
      return result
    }
  }

}
