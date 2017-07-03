//
//  ScanTask.swift
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

/// Completion block of scanning things. If successful, an array of `ThingInfo`
/// objects are returned, representing the discovered things. If failed,
/// a corresponding error object is returned.
public typealias ScanResultBlock = (Result<[ThingInfo]>)->()

class ScanTask: BLETask {
  
  var centralManager: BLECentralManaging
  var isOngoing: Bool {
    get {
      return discoveredThings != nil
    }
  }
  var taskCompletionBlock: (() -> ())?
  
  private var discoveredThings: [UUID: ThingInfo]?
  private var timer: Timer?
  private var completion: ScanResultBlock
  
  init(centralManager: BLECentralManaging, timeout: TimeInterval, completion: @escaping ScanResultBlock) {
    self.centralManager = centralManager
    self.completion = completion
    self.timer = Timer(timeInterval: timeout, repeats: false, block: { [weak self] _ in
      self?.handleScanTimeUp(completion: completion)
    })
  }
  
  @objc func start() {
    if isOngoing {
      return
    }
    
    if centralManager.state == .poweredOn {
      startScanning()
    }
  }
  
  private func startScanning() {
    guard let timer = timer else {
      assert(false)
      return
    }
    
    discoveredThings = [:]
    centralManager.scanForPeripherals(withServices: nil, options: nil)
    RunLoop.main.add(timer, forMode: .defaultRunLoopMode)
  }
  
  private func handleScanTimeUp(completion: ScanResultBlock) {
    centralManager.stopScan()
    if let discoveredThings = discoveredThings {
      let thingInfo = Array(discoveredThings.values)
      completion(Result.success(thingInfo))
    } else {
      completion(Result.error(ScanError.timeout))
    }
    taskCompletionBlock?()
  }
  
  func fail(_ error: Error) {
    completion(Result.error(error))
  }
  
  func didDiscover(_ peripheral: BLEPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    let isGeenyNative = advertisesGeenyService(advertisementData)
    let basics = ThingInfo(family: .physicalThing, name: peripheral.name, peripheralId: peripheral.identifier.uuidString, isGeenyNative: isGeenyNative)
    discoveredThings?[peripheral.identifier] = basics
  }
  
  private func advertisesGeenyService(_ advertisementData: [String: Any]) -> Bool {
    var advertises = false
    if let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
      if serviceUUIDs.contains(BLECommunicator.geenyServiceUUID) {
        advertises = true
      }
    }
    return advertises
  }
  
  func didConnect(_ peripheral: BLEPeripheral) {}
  
  func didFailToConnect(_ peripheral: BLEPeripheral, error: Error?) {}
  
}

