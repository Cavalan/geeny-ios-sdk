//
//  GATTDetector.swift
//  BLEServiceBrowser
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit
import CoreBluetooth

/// Completion block of GATT detection. If successful, a `ThingInfo` object
/// is returned with metadata representing the thing. If failed,
/// a corresponding error object is returned.
public typealias GATTResultBlock = (Result<([CharacteristicInfo],GeenyThingInfo?)>)->()

class GATTDetector: NSObject {
  
  private var targetPeripheral: BLEPeripheral?
  private var previousDelegate: CBPeripheralDelegate?
  
  private var remainingServiceUDIDs = Set<CBUUID>()
  private var characteristicInfos = [CharacteristicInfo]()
  private var potentialGeenyCharacteristic: CBCharacteristic?
  
  private var completionBlock: GATTResultBlock?
  
  func discover(peripheral: BLEPeripheral, completion: @escaping GATTResultBlock) {
    if let _ = completionBlock {
      completion(.error(GatewayError.busyPleaseRetryLater))
      return
    }
    
    // Setup states
    targetPeripheral = peripheral
    previousDelegate = peripheral.delegate
    remainingServiceUDIDs.removeAll()
    characteristicInfos.removeAll()
    potentialGeenyCharacteristic = nil
    completionBlock = completion
    assert(peripheral.state == .connected)
      
    startDiscovering(peripheral)
  }
  
  private func startDiscovering(_ peripheral: BLEPeripheral) {
    peripheral.delegate = self
    peripheral.discoverServices(nil)
  }
  
  private func finalize(characteristics: [CharacteristicInfo], geenyThingInfo: GeenyThingInfo?) {
    targetPeripheral?.delegate = previousDelegate
    completionBlock?(Result.success((characteristics, geenyThingInfo)))
    cleanUp()
  }
  
  private func finalize(error: Error) {
    targetPeripheral?.delegate = previousDelegate
    completionBlock?(Result.error(error))
    cleanUp()
  }
  
  private func cleanUp() {
    previousDelegate = nil
    targetPeripheral = nil
    potentialGeenyCharacteristic = nil
    completionBlock = nil
  }
  
}

extension GATTDetector: CBPeripheralDelegate {
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    if let error = error {
      // Discover failed
      finalize(error: error)
      return
    }
    
    guard let services = peripheral.services,
      !services.isEmpty else {
        finalize(characteristics: [], geenyThingInfo: nil)
      return
    }
    
    for service in services {
      remainingServiceUDIDs.insert(service.uuid)
    }

    for service in services {
      peripheral.discoverCharacteristics(nil, for: service)
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    // Collect characteristics
    let serviceUUID = service.uuid.uuidString
    if let characteristics = service.characteristics {
      for characteristic in characteristics {
        let properties = CharacteristicProperties(rawValue: characteristic.properties.rawValue)
        let characteristicUUID = characteristic.uuid.uuidString
        // TODO topic mapping
        let info = CharacteristicInfo(uuid: characteristicUUID, description: characteristicUUID, topic: characteristicUUID, properties: properties)
        characteristicInfos.append(info)
        
        // Check if is potentially Geeny compatible
        if serviceUUID.caseInsensitiveCompare(GeenyThingInfo.serviceId) == .orderedSame &&
          characteristicUUID.caseInsensitiveCompare(GeenyThingInfo.characteristicId) == .orderedSame {
          potentialGeenyCharacteristic = characteristic
        }
      }
    }
    
    // Count down
    remainingServiceUDIDs.remove(service.uuid)
    if remainingServiceUDIDs.isEmpty {
      if let potentialGeenyCharacteristic = potentialGeenyCharacteristic {
        peripheral.readValue(for: potentialGeenyCharacteristic)
      } else {
        finalize(characteristics: characteristicInfos, geenyThingInfo: nil)
      }
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    if let potentialGeenyCharacteristic = potentialGeenyCharacteristic,
      characteristic == potentialGeenyCharacteristic,
      let data = characteristic.value,
      let geenyInfo = GeenyThingInfoParser.parseData(data) {
      finalize(characteristics: characteristicInfos, geenyThingInfo: geenyInfo)
    } else {
      finalize(characteristics: characteristicInfos, geenyThingInfo: nil)
    }
  }
  
}
