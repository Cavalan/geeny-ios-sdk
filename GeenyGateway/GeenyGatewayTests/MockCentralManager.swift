//
//  MockCentralManager.swift
//  GeenyGatewayTests
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit
import CoreBluetooth
@testable import GeenyGateway

class MockPeripheral: NSObject, BLEPeripheral {
  
  weak var delegate: CBPeripheralDelegate?
  
  let name: String?
  let identifier: UUID
  var state: CBPeripheralState
  
  var lastWrittenData: Data?
  var lastWrittenCharacteristic: CharacteristicInfo?
  
  init(name: String?, identifier: UUID, state: CBPeripheralState) {
    self.name = name
    self.identifier = identifier
    self.state = state
    super.init()
  }
  
  func discoverServices(_ serviceUUIDs: [CBUUID]?) {}
  func readValue(for characteristicInfo: CharacteristicInfo) {}
  func setNotifyValue(_ enabled: Bool, for characteristic: CharacteristicInfo) {}
  func writeValue(_ data: Data, for characteristicInfo: CharacteristicInfo) {
    lastWrittenData = data
    lastWrittenCharacteristic = characteristicInfo
  }

}

class MockCentralManager: NSObject, BLECentralManaging {
  var state: CBManagerState = .unknown {
    didSet {
      geenyDelegate?.geeny_centralManagerDidUpdateState(self)
    }
  }
  weak var geenyDelegate: BLECentralManagerDelegate?
  
  var peripherals = [BLEPeripheral]()
  
  func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]?) {
    guard state == .poweredOn else {
      return
    }
    for peripheral in peripherals {
      geenyDelegate?.geeny_centralManager(self, didDiscover: peripheral, advertisementData: [:], rssi: -45)
    }
  }
  
  func stopScan() {}
  
  func connect(_ peripheral: BLEPeripheral, options: [String : Any]?) {
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.5) {
      self.geenyDelegate?.geeny_centralManager(self, didConnect: peripheral)
    }
    
  }

}
