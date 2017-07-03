//
//  BLECentralManaging.swift
//  GeenyGateway
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit
import CoreBluetooth

protocol BLECentralManaging: NSObjectProtocol {
  var state: CBManagerState { get }
  weak var geenyDelegate: BLECentralManagerDelegate? { get set }
  
  func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]?)
  func stopScan()
  
  func connect(_ peripheral: BLEPeripheral, options: [String : Any]?)
}

protocol BLEPeripheral: NSObjectProtocol {
  var name: String? { get }
  var identifier: UUID { get }
  var state: CBPeripheralState { get }
  weak var delegate: CBPeripheralDelegate? { get set }
  
  func discoverServices(_ serviceUUIDs: [CBUUID]?)
  func readValue(for characteristicInfo: CharacteristicInfo)
  func setNotifyValue(_ enabled: Bool, for characteristic: CharacteristicInfo)
  func writeValue(_: Data, for: CharacteristicInfo)
}

protocol BLECentralManagerDelegate: NSObjectProtocol {
  func geeny_centralManagerDidUpdateState(_ central: BLECentralManaging)
  func geeny_centralManager(_ central: BLECentralManaging, didDiscover peripheral: BLEPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
  func geeny_centralManager(_ central: BLECentralManaging, didConnect peripheral: BLEPeripheral)
  func geeny_centralManager(_ central: BLECentralManaging, didDisconnectPeripheral peripheral: BLEPeripheral, error: Error?)
  func geeny_centralManager(_ central: BLECentralManaging, didFailToConnect peripheral: BLEPeripheral, error: Error?)
}

// MARK: - CoreBluetooth conformance

extension CBCentralManager: BLECentralManaging {
  weak var geenyDelegate: BLECentralManagerDelegate? {
    get {
      return delegate as? BLECentralManagerDelegate
    }
    set {
      if let cbDelegate = newValue as? CBCentralManagerDelegate {
        delegate = cbDelegate
      }
    }
  }
  
  func connect(_ peripheral: BLEPeripheral, options: [String : Any]?) {
    if let cbPeripheral = peripheral as? CBPeripheral {
      connect(cbPeripheral, options: options)
    }
  }
}

extension CBCentralManagerDelegate where Self: BLECentralManagerDelegate {}

extension CBPeripheral: BLEPeripheral {
  
  func writeValue(_ data: Data, for characteristicInfo: CharacteristicInfo) {
    if let characteristic = geenyCharacteristicMatching(characteristicInfo) {
      // write value to the Thing
      let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse
      writeValue(data, for: characteristic, type: writeType)
    }
  }
  
  
  func readValue(for characteristicInfo: CharacteristicInfo) {
    if let characteristic = geenyCharacteristicMatching(characteristicInfo) {
      readValue(for: characteristic)
    }
  }
  
  func setNotifyValue(_ enabled: Bool, for characteristic: CharacteristicInfo) {
    if let characteristic = geenyCharacteristicMatching(characteristic) {
      setNotifyValue(enabled, for: characteristic)
    }
  }
  
}

