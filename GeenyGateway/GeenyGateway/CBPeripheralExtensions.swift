//
//  CBPeripheralExtensions.swift
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

extension CBPeripheral {
  
  func geenyCharacteristicMatching(_ info: CharacteristicInfo) -> CBCharacteristic? {
    if let services = services {
      for service in services {
        if let characteristics = service.characteristics {
          for characteristic in characteristics {
            if characteristic.uuid.uuidString == info.uuid {
              return characteristic
            }
          }
        }
      }
    }
    return nil
  }
  
}

