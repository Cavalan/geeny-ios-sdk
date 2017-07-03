//
//  MqttPublishing.swift
//  BLEServiceBrowser
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit

public enum MQTTError: Error {
  case certificateFileNotFound
  case certificateCannotBeImported
  case connectionRefused
  case connectionError
  case protocolError
  case unknown
}

public enum MQTTStatus {
  case connecting
  case connected
  case disconnected
  case error(detail: MQTTError)
}

protocol MQTTConnecting: class {
  weak var delegate: MQTTConnectingDelegate? { get set }
  typealias MQTTStatusBlockType = (MQTTStatus)->Void
  typealias MQTTResponseBlockType = (String, Data)->Void
  func connect(statusBlock: @escaping MQTTStatusBlockType)
  func disconnect()
  
  func publishString(_ text: String, onTopic topic: String)
  func publishData(_ data: Data, onTopic topic: String)
  func subscribe(toTopic topic: String)
  func unsubscribe(fromTopic topic: String)
}

protocol MQTTConnectingDelegate: class {
  func onDataFromCloud(_ data: Data, onTopic topic: String)
}

