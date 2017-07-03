//
//  ThingProvider.swift
//  GeenyGateway
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit
import RxSwift

class ThingProvider: NSObject {
  
  private let bleCommunicator: BLECommunicator
  private let registrationCache: RegistrationCache
  private let certificateStore: CertificateStore
  private var notRegisteredThings = [String:Thing]()
  private var registeredThings = [String:Thing]()

  init(bleCommunicator: BLECommunicator, registrationCache: RegistrationCache, certificateStore: CertificateStore) {
    self.bleCommunicator = bleCommunicator
    self.registrationCache = registrationCache
    self.certificateStore = certificateStore
  }
  
  func thing(with thingInfo: ThingInfo) -> Thing {

    var thing: Thing
    if let thingInfo = registrationCache.thingInfo(forThingUUID: thingInfo.peripheralId), let thingId = thingInfo.geenyId {
      // registered things
      if let thing = registeredThings[thingInfo.peripheralId] {
        return thing
      }
      let mqttConnector: MQTTConnecting = MoscapsuleMQTTConnector(peripheralId: thingInfo.peripheralId, thingId: thingId, certificateStore: certificateStore)
      
      if let peripheral = bleCommunicator.connectedPeripheral(withIdentifier: thingInfo.peripheralId) {
        // it's a BLE peripheral
        thing = Thing(info: thingInfo, peripheral: peripheral, mqttConnector: mqttConnector)
      } else {
        // it's a virtual thing with no direct peripheral
        thing = Thing(info: thingInfo, mqttConnector: mqttConnector)
      }
      registeredThings[thingInfo.peripheralId] = thing

    } else {
      // not registered things
      if let thing = notRegisteredThings[thingInfo.peripheralId] {
        return thing
      }
      thing = Thing(info: thingInfo)
      notRegisteredThings[thingInfo.peripheralId] = thing
    }
    return thing;
  }
  
}
