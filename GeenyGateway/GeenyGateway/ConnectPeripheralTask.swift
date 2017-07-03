//
//  ConnectPeripheralTask.swift
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

typealias PeripheralBlock = (Result<BLEPeripheral>) -> Void

class ConnectPeripheralTask: BLETask {
  
  var centralManager: BLECentralManaging
  var isOngoing = false
  var taskCompletionBlock: (() -> ())?
  
  private var peripheralIdToConnect: UUID
  private var completion: PeripheralBlock
  private var peripheralToConnect: BLEPeripheral?
  private var isCancelled = false
  
  init(centralManager: BLECentralManaging, peripheralId: UUID, completion: @escaping PeripheralBlock) {
    self.centralManager = centralManager
    self.peripheralIdToConnect = peripheralId
    self.completion = completion
  }
  
  func start() {
    if isOngoing || isCancelled {
      return
    }
    
    isOngoing = true
    centralManager.scanForPeripherals(withServices: nil, options: nil)
  }
  
  func cancel() {
    isCancelled = true
    completion(.error(GatewayError.cancelled))
    taskCompletionBlock?()
  }

  func fail(_ error: Error) {
    completion(Result.error(error))
    taskCompletionBlock?()
  }
  
  func didDiscover(_ peripheral: BLEPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
    if isCancelled {
      centralManager.stopScan()
      return
    }
    
    if peripheral.identifier == peripheralIdToConnect {
      centralManager.stopScan()
      if peripheral.state == .connected {
        completion(.success(peripheral))
        taskCompletionBlock?()
      } else {
        peripheralToConnect = peripheral
        centralManager.connect(peripheral, options: nil)
      }
    }
  }
  
  func didConnect(_ peripheral: BLEPeripheral) {
    if isCancelled {
      return
    }
    
    if peripheral.identifier == peripheralIdToConnect {
      peripheralToConnect = nil
      completion(.success(peripheral))
      taskCompletionBlock?()
    }
  }
  
  func didFailToConnect(_ peripheral: BLEPeripheral, error: Error?) {
    if let error = error {
      completion(Result.error(error))
    } else {
      completion(Result.error(GatewayError.pleaseRetryLater))
    }
    taskCompletionBlock?()
  }

}
