//
//  DisplayName.swift
//  GatewayExample
//
//  Created by Shuo Yang on 7/25/17.
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit

class DisplayName {
  
  static func fullNameFrom(thingName: String?, userGivenName: String?, separator: String) -> String {
    var names = [String]()
    names.append(thingNameOrUnknown(thingName))
    if let userGivenName = userGivenName {
      names.append("(\(userGivenName))")
    }
    return names.joined(separator: separator)
  }
  
  static func thingNameOrUnknown(_ thingName: String?) -> String {
    return thingName ?? "<Unknown>"
  }
  
}

