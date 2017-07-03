//
//  BLECommunicator.swift
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

class BLECommunicator: NSObject {
  static let geenyServiceUUID = CBUUID(string: GeenyThingInfo.serviceId)
  
  private let centralManager: BLECentralManaging
  private var currentTask: BLETask?
  private var connectedPeripherals = [UUID: BLEPeripheral]()
  private var connectedPeripheralsCharacteristics = [UUID: ([CharacteristicInfo],GeenyThingInfo?)]()
  
  private let gattDetector = GATTDetector()
  
  init(centralManager: BLECentralManaging) {
    self.centralManager = centralManager
    super.init()
    self.centralManager.geenyDelegate = self
  }
  
  func handleTask(_ task: BLETask) {
    if centralManager.state == .poweredOn {
      task.start()
    } else if let error = hasUnrecoverableScanError(central: centralManager) {
      task.fail(error)
    }
  }
  
  private func hasUnrecoverableScanError(central: BLECentralManaging) -> ScanError? {
    switch central.state {
    case .poweredOn, .resetting, .unknown:
      return nil
    case .poweredOff:
      return .poweredOff
    case .unsupported:
      return .unsupported
    case .unauthorized:
      // This shouldn't happen
      assert(false)
    }
  }
  
  private func cleanUp() {
    currentTask = nil
  }
  
  // MARK: - Scanning
  
  func scanForThings(timeout: TimeInterval, completion: @escaping ScanResultBlock) {
    if currentTask != nil {
      completion(.error(GatewayError.busyPleaseRetryLater))
      return
    }
    
    // Setup task
    let scanTask = ScanTask(centralManager: centralManager, timeout: timeout, completion: completion)
    scanTask.taskCompletionBlock = { [weak self] in
      self?.cleanUp()
    }
    currentTask = scanTask
    
    handleTask(scanTask)
  }
  
  func detectGATT(in peripheral: BLEPeripheral, completion: @escaping GATTResultBlock) {

    if let characteristicsAndGeenyThingInfo = connectedPeripheralsCharacteristics [peripheral.identifier] {
      completion(Result.success(characteristicsAndGeenyThingInfo))
    }

    gattDetector.discover(peripheral: peripheral) { [weak self] result in

      switch result {
      case .success(let characteristicsAndGeenyThingInfo):
        self?.connectedPeripheralsCharacteristics[peripheral.identifier] = characteristicsAndGeenyThingInfo
        completion(Result.success(characteristicsAndGeenyThingInfo))
      default: completion(result)
      }
    }
  }
  
  // MARK: - Peripheral Lookup
  
  func connectedPeripheral(withIdentifier identifier: String) -> BLEPeripheral? {
    if let uuid = UUID(uuidString: identifier) {
      return connectedPeripherals[uuid]
    } else {
      return nil
    }
  }
  
  
  func connectToPeripheral(withIdentifier identifier: String, completion: @escaping PeripheralBlock) -> Progress {

    let progress = Progress(totalUnitCount: 0)

    guard let uuid = UUID(uuidString: identifier) else {
      completion(.error(GatewayError.invalidUUIDString))
      return progress
    }

    if let connectedPeripheral = connectedPeripherals[uuid] {
      completion(.success(connectedPeripheral))
      return progress
    }

    if currentTask != nil {
      completion(.error(GatewayError.busyPleaseRetryLater))
      return progress
    }

    return reconnectToPeripheral(with: uuid, completion: completion)
  }

  
  func reconnectToPeripheral(with uuid: UUID, completion: @escaping PeripheralBlock) -> Progress {
    let progress = Progress(totalUnitCount: 0)
    let connectTask = ConnectPeripheralTask(centralManager: centralManager, peripheralId: uuid, completion: completion)
    connectTask.taskCompletionBlock = { [weak self] in
      self?.cleanUp()
    }
    currentTask = connectTask
    progress.cancellationHandler = {
      connectTask.cancel()
    }
    handleTask(connectTask)
    return progress
  }
}


// MARK: - CentralManagerDelegate conformance

// Forwarding calls to BLECentralManagerDelegate in order to unit test this class.
extension BLECommunicator: CBCentralManagerDelegate {
  
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    geeny_centralManagerDidUpdateState(central)
  }
  
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    geeny_centralManager(central, didDiscover: peripheral, advertisementData: advertisementData, rssi: RSSI)
  }
  
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    geeny_centralManager(central, didConnect: peripheral)
  }
  
  func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    geeny_centralManager(central, didFailToConnect: peripheral, error: error)
  }
  
  func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    geeny_centralManager(central, didDisconnectPeripheral: peripheral, error: error)
  }
  
}

extension BLECommunicator: BLECentralManagerDelegate {

  func geeny_centralManagerDidUpdateState(_ central: BLECentralManaging) {
    if let currentTask = currentTask,
      !currentTask.isOngoing {
      handleTask(currentTask)
    }
  }
  
  func geeny_centralManager(_ central: BLECentralManaging, didDiscover peripheral: BLEPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    currentTask?.didDiscover(peripheral, advertisementData: advertisementData, rssi: RSSI)
  }
  
  func geeny_centralManager(_ central: BLECentralManaging, didConnect peripheral: BLEPeripheral) {
    connectedPeripherals[peripheral.identifier] = peripheral
    currentTask?.didConnect(peripheral)
  }
  
  func geeny_centralManager(_ central: BLECentralManaging, didDisconnectPeripheral peripheral: BLEPeripheral, error: Error?) {
    connectedPeripherals.removeValue(forKey: peripheral.identifier)
    connectedPeripheralsCharacteristics.removeValue(forKey: peripheral.identifier)
  }

  func geeny_centralManager(_ central: BLECentralManaging, didFailToConnect peripheral: BLEPeripheral, error: Error?) {
    connectedPeripherals.removeValue(forKey: peripheral.identifier)
    connectedPeripheralsCharacteristics.removeValue(forKey: peripheral.identifier)
    currentTask?.didFailToConnect(peripheral, error: error)
  }
  
}
