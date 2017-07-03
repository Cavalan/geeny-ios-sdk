//
//  Config.swift
//  GatewayExample
//
//  Created by Risalba on 21.08.17.
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import Foundation
// uuid: your device's characacteristic's uuid
// topic: URI of a characteristic in your ThingType in the Geeny Cloud
typealias CharacteristicsInfoConfig = (uuid:String, topic: String)
struct Config {
  // We match a `notify` characteristic with a `pub` topic. We assigned the uuid of the characteristic as the URI for convenience.
  // We will receive the data coming from the thing and publish it to the Geeny Cloud
  static let publishCharacteristicInfo = CharacteristicsInfoConfig(uuid: "0000CAFE-C001-DE30-CABB-785FEABCD123", topic: "0000CAFE-C001-DE30-CABB-785FEABCD123")
  // We match a `write` characteristic with a `sub` topic. We assigned the uuid of the characteristic as the URI for convenience.
  // We will subscribe to data coming from the Geeny Cloud and write them to our Thing
  static let subscribeCharacteristicInfo = CharacteristicsInfoConfig(uuid: "0000DA7A-C001-DE30-CABB-785FEABCD123", topic: "0000DA7A-C001-DE30-CABB-785FEABCD123")
}

