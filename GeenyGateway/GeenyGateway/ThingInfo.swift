//
//  ThingInfo.swift
//  GeenyGateway
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit

public enum ThingFamily: Int, CustomStringConvertible, Codable {
  case physicalThing
  case virtualThing
  
  public var description: String {
    switch self {
    case .physicalThing:
      return "Physical"
    case .virtualThing:
      return "Virtual"
    }
  }
}

/// The second-level metadata of a Thing. Represents all metadata of a Thing,
/// including its identifier, the characteristics and Geeny Thing Info.
public struct ThingInfo: Codable {
  internal let family: ThingFamily
  
  /// The name of the thing if it has one.
  public let name: String?

  /// The name given to the thing when registering in the Geeny Cloud.
  public let userGivenName: String?

  /// The peripheral identifier of the Thing returned by `CBPeer`.
  ///
  /// - Important:
  /// Notice that this identifier is *not* the hardware identifier and *can change
  /// at any time* for privacy reasons.
  ///
  /// - SeeAlso:
  ///   [CBPeer.identifier documentation](https://developer.apple.com/documentation/corebluetooth/cbpeer/1620687-identifier)
  /// - SeeAlso:
  ///   [StackOverflow discussion of the identifier uniqueness](https://stackoverflow.com/a/36710800)
  public let peripheralId: String

  /// Geeny cloud Id present if the thing is registered.
  public let geenyId: String?

  /// Returns whether the Thing is Geeny-native, i.e. whether it advertises
  /// the Geeny Information Service.
  public let isGeenyNative: Bool

  /// All Geeny-native things contain the Geeny Information Service,
  /// whose data is contained here.
  public let geenyThingInfo: GeenyThingInfo?

  /// All characteristics of the thing.
  public let characteristics: [CharacteristicInfo]

  /// Should the data be sent from notifying characteristics to the cloud automatically?
  public let autoPublish: Bool

  /// Generate a pretty printed string representation of the object.
  public func prettyPrintString() -> String {
    var result = """
    ==== ThingInfo BEGIN ====
      | family: \(family)
      | peripheralId: \(peripheralId)\n
    """
    if let geenyThingInfo = geenyThingInfo {
      result += """
        | isGeenyNative? YES
        | - [geeny]
        |   protocolVersion: \(geenyThingInfo.protocolVersion)
        |   serialNumber: \(geenyThingInfo.serialNumber)
        |   thingType: \(geenyThingInfo.thingType)\n
      """
    } else {
      result += "  | isGeenyNative? \(isGeenyNative ? "YES" : "NO")\n"
    }
    for characteristic in characteristics {
      result += """
        | - [characteristic]
        |   UUID: \(characteristic.uuid)
        |   desc: \(characteristic.description)
        |   prop: \(characteristic.properties)\n
      """
    }
    result += "==== ThingInfo END ====\n"
    return result
  }

  public init(family: ThingFamily, name: String?, userGivenName: String? = nil, peripheralId: String, geenyId: String? = nil, isGeenyNative: Bool = false, geenyThingInfo: GeenyThingInfo? = nil, characteristics: [CharacteristicInfo] = [], autoPublish: Bool = true) {
    self.family = family
    self.name = name
    self.userGivenName = userGivenName
    self.peripheralId = peripheralId
    self.geenyId = geenyId
    self.isGeenyNative = isGeenyNative
    self.geenyThingInfo = geenyThingInfo
    self.characteristics = characteristics
    self.autoPublish = autoPublish
  }

  internal func updatedWith(userGivenName: String? = nil, geenyId: String? = nil, geenyThingInfo: GeenyThingInfo? = nil, characteristics: [CharacteristicInfo]? = nil, autoPublish: Bool? = nil) -> ThingInfo {
    let userGivenName = userGivenName ?? self.userGivenName
    let geenyId = geenyId ?? self.geenyId
    let isGeenyNative = geenyThingInfo != nil ? true : self.isGeenyNative
    let geenyThingInfo = geenyThingInfo ?? self.geenyThingInfo
    let characteristics = characteristics ?? self.characteristics
    let autoPublish = autoPublish ?? self.autoPublish
    return ThingInfo(family: self.family, name: self.name, userGivenName: userGivenName, peripheralId: self.peripheralId, geenyId: geenyId, isGeenyNative: isGeenyNative, geenyThingInfo: geenyThingInfo, characteristics: characteristics, autoPublish: autoPublish)
  }

  public func updatedWith(autoPublish: Bool? = nil) -> ThingInfo {
    let autoPublish = autoPublish ?? self.autoPublish
    return ThingInfo(family: self.family, name: self.name, userGivenName: self.userGivenName, peripheralId: self.peripheralId, geenyId: self.geenyId, isGeenyNative: self.isGeenyNative, geenyThingInfo: self.geenyThingInfo, characteristics: self.characteristics, autoPublish: autoPublish)
  }

}
