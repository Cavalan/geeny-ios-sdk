//
//  BLETask.swift
//  GeenyGateway
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit

protocol BLETask {
  var centralManager: BLECentralManaging { get }
  var isOngoing: Bool { get }
  var taskCompletionBlock: (() -> ())? { get set }
  
  func start()
  func fail(_ error: Error)
  
  func didDiscover(_ peripheral: BLEPeripheral, advertisementData: [String : Any], rssi: NSNumber)
  func didConnect(_ peripheral: BLEPeripheral)
  func didFailToConnect(_ peripheral: BLEPeripheral, error: Error?)
}

