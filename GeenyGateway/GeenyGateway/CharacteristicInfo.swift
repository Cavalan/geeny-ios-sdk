//
//  CharacteristicInfo.swift
//  GeenyGateway
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit

/// The basic unit of a Thing as in our abstraction. For Bluetooth LE
/// devices, this maps to a Characteristic. For virtual things (coming soon),
/// this represents a communication channel of the thing.
public struct CharacteristicInfo: Codable {
  /// UUID of the characteristic
  public let uuid: String
  /// Description of the characteristic
  public let description: String
  /// MQTT topic for this characteristic
  public let topic: String
  /// properties describe if the characteristic supports read / write / notify / indicate / etc.
  /// More information about the options in `CharacteristicProperties`
  public let properties: CharacteristicProperties

  public init(uuid: String, description: String, topic: String, properties: CharacteristicProperties) {
    self.uuid = uuid
    self.description = description
    self.topic = topic
    self.properties = properties
  }
}

/// Values representing the possible types of writes to a characteristic’s value.
/// For Bluetooth LE devices, this maps to a CBCharacteristicWriteType.
public enum CharacteristicWriteType {
  /// A characteristic value is to be written, with a response from the peripheral to indicate whether the write was successful.
  case withResponse
  /// A characteristic value is to be written, without any response from the peripheral to indicate whether the write was successful.
  case withoutResponse
}

/// Matches [CBCharacteristicProperties](https://developer.apple.com/documentation/corebluetooth/cbcharacteristicproperties)
/// Defined within SDK module so that
/// user doesn't have to import CoreBluetooth if they don't require Bluetooth
/// communication (for example with Virtual Things).
public struct CharacteristicProperties: OptionSet, Codable {
  /// Numeric representation of the characteristic property
  public let rawValue: UInt
  
  /// The characteristic’s value can be broadcast using a characteristic configuration descriptor.
  public static let broadcast = CharacteristicProperties(rawValue: 0x01)
  /// The characteristic’s value can be read.
  public static let read = CharacteristicProperties(rawValue: 0x02)
  /// The characteristic’s value can be written, without a response from the peripheral to indicate that the write was successful.
  public static let writeWithoutResponse = CharacteristicProperties(rawValue: 0x04)
  /// The characteristic’s value can be written, with a response from the peripheral to indicate that the write was successful.
  public static let write = CharacteristicProperties(rawValue: 0x08)
  /// Notifications of the characteristic’s value are permitted, without a response from the central to indicate that the notification was received.
  public static let notify = CharacteristicProperties(rawValue: 0x10)
  /// Indications of the characteristic’s value are permitted, with a response from the central to indicate that the indication was received.
  public static let indicate = CharacteristicProperties(rawValue: 0x20)
  /// Signed writes of the characteristic’s value are permitted, without a response from the peripheral to indicate that the write was successful.
  public static let authenticatedSignedWrites = CharacteristicProperties(rawValue: 0x40)
  /// Additional characteristic properties are defined in the characteristic extended properties descriptor.
  public static let extendedProperties = CharacteristicProperties(rawValue: 0x80)
  /// Only trusted devices can enable notifications of the characteristic’s value.
  public static let notifyEncryptionRequired = CharacteristicProperties(rawValue: 0x100)
  /// Only trusted devices can enable indications of the characteristic’s value.
  public static let indicateEncryptionRequired = CharacteristicProperties(rawValue: 0x200)
  
  private static let orderedProperties: [CharacteristicProperties] = [.broadcast, .read, .writeWithoutResponse, .write, .notify, .indicate, .authenticatedSignedWrites, .extendedProperties, .notifyEncryptionRequired, .indicateEncryptionRequired]

  
  
  public init(rawValue: UInt) {
    self.rawValue = rawValue
  }
}

