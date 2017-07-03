//
//  MoscapsuleMQTTConnector.swift
//  Gateway SDK
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit
import Moscapsule

class MoscapsuleMQTTConnector: NSObject, MQTTConnecting {
  
  weak var delegate: MQTTConnectingDelegate?
  // The identifier from the Geeny cloud identifying the Thing
  private let peripheralId: String
  private let thingId: String
  private let certificateStore: CertificateStore
  private var mqttClient: MQTTClient?
  
  init(peripheralId: String, thingId: String, certificateStore: CertificateStore) {
    self.peripheralId = peripheralId
    self.thingId = thingId
    self.certificateStore = certificateStore
    super.init()
  }
  
  func connect(statusBlock: @escaping MQTTStatusBlockType) {
    if let mqttClient = mqttClient,
      mqttClient.isConnected {
      statusBlock(.connected)
      return
    }
    
    guard let certificatePaths = certificateStore.certificatePaths(for: peripheralId) else {
      print("[WARN] Could not find certificates paths in keychain for \(thingId)")
      statusBlock(.error(detail: .certificateFileNotFound))
      return
    }
    
    let documentsFolder = PathUtils.documentsFolderPath() as NSString
    let caCertPath = documentsFolder.appendingPathComponent(certificatePaths.caCertificatePath)
    let clientCertPath = documentsFolder.appendingPathComponent(certificatePaths.clientCertificatePath)
    let privateKeyPath = documentsFolder.appendingPathComponent(certificatePaths.encryptedKeyPath)
    
    let config = MQTTConfig(clientId: thingId, host: Endpoint.mqttHost, port: 8883, keepAlive: 60, protocolVersion: .v3_1_1)
    config.onConnectCallback = { returnCode in
      let status = MQTTStatus.from(returnCode: returnCode)
      statusBlock(status)
    }
    
    config.onMessageCallback = { mqttMessage in
      if let data = mqttMessage.payload {
        // Currently we send and receive the full topic's URI, in the future we might receive only the topic already routed to the corresponding device
        let topicUriParts = mqttMessage.topic.split(separator: "/")
        if let thingId = topicUriParts.first, let topic = topicUriParts.last, thingId == self.thingId {
          self.delegate?.onDataFromCloud(data, onTopic: String(topic))
        }
      }
    }
    
    config.mqttServerCert = MQTTServerCert(cafile: caCertPath, capath: nil)
    config.mqttClientCert = MQTTClientCert(certfile: clientCertPath, keyfile: privateKeyPath, keyfile_passwd: thingId)
    
    moscapsule_init()
    mqttClient = MQTT.newConnection(config, connectImmediately: true)
  }
  
  func publishString(_ text: String, onTopic topic: String) {
    assert(mqttClient != nil)
    mqttClient!.publish(string: text, topic: topic, qos: Qos.exactly_once, retain: false)
  }
  
  func publishData(_ data: Data, onTopic topic: String) {
    assert(mqttClient != nil)
    mqttClient!.publish(data, topic: topic, qos: Qos.exactly_once, retain: false)
  }
  
  func subscribe(toTopic topic: String) {
    assert(mqttClient != nil)
    // In the future the backend might create the topic URI using the topic and the header so we would only send the topic
    let topicUri = [self.thingId, topic].joined(separator: "/")
    mqttClient!.subscribe(topicUri, qos: Qos.exactly_once) { (result, messageId) in
      switch result {
      case .mosq_success:
        print("Subscribed successfully to topic: \(topicUri)")
      default:
        print("FAILED: subscription to topic: \(topicUri) with MosqResult:\(result) and messageId:\(messageId)")
      }
    }
  }

  func unsubscribe(fromTopic topic: String) {
    assert(mqttClient != nil)
    // In the future the backend might create the topic URI using the topic and the header so we would only send the topic
    let topicUri = [self.thingId, topic].joined(separator: "/")
    mqttClient!.unsubscribe(topicUri) { (result, messageId) in
      switch result {
      case .mosq_success:
        print("Unsuscribed successfully from topic: \(topicUri)")
      default:
        print("FAILED: to unsubscribe from topic: \(topicUri) with MosqResult:\(result) and messageId:\(messageId)")
      }
    }
  }

  func disconnect() {
    mqttClient?.disconnect()
    mqttClient = nil
  }
  
}

fileprivate extension MQTTStatus {
  
  static func from(returnCode: ReturnCode) -> MQTTStatus {
    switch returnCode {
    case .success:
      return .connected
    case .unacceptable_protocol_version:
      return .error(detail: .protocolError)
    default:
      return .error(detail: .connectionError)
    }
  }
  
}

