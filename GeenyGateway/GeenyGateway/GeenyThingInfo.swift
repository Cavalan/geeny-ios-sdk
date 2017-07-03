//
//  GeenyThingInfo.swift
//  GeenyGateway
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit

/// All Geeny-native things contains the Geeny Information Service.
/// This struct represents the values from the Geeny Information Service.
public struct GeenyThingInfo: Codable {
  static let serviceId = "0F050001-3225-44B1-B97D-D3274ACB29DE"
  static let characteristicId = "0F050002-3225-44B1-B97D-D3274ACB29DE"
  
  /// Protocol version number of the Geeny Information Service.
  /// Data in protocols of different versions may need to be decoded differently.
  public let protocolVersion: UInt
  /// Serial number of the Geeny-native thing.
  public let serialNumber: String
  /// Thing type of the Geeny-native thing.
  public let thingType: String
}

