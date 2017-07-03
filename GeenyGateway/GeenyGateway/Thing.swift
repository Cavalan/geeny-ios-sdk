//
//  Thing.swift
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

public typealias DataResult = (Result<Data>)->(Data?)

/// The Thing that gets connected and routed via the GeenyGateway
/// Abstracts the connections to (Geeny Cloud, Bluetooth LE, MQTT, ...)
public class Thing: NSObject, MQTTConnectingDelegate {
  
  

  private struct DataInterception {
    let characteristicInfo: CharacteristicInfo
    let completion: DataResult
    let reuse: Bool
  }
  private class DataInterceptionQueue {
    
    private var queue = [DataInterception]()
    
    func dataInterception(for characteristicInfo: CharacteristicInfo) -> DataInterception? {
      return queue.filter { $0.characteristicInfo.uuid == characteristicInfo.uuid }.first
    }
    
    func dataInterception(for characteristicTopic: String)  -> DataInterception? {
      // currently MQTT Topics are named after BLE characteristic UUIDs
      return queue.filter { $0.characteristicInfo.topic == characteristicTopic }.first
    }
    
    func append(_ interception: DataInterception) {
      queue.append(interception)
    }
    func remove(with characteristicInfo: CharacteristicInfo) {
      queue = queue.filter { $0.characteristicInfo.uuid != characteristicInfo.uuid }
    }
  }

  public var info: ThingInfo {
    willSet(newInfo) {
      if !info.autoPublish  && newInfo.autoPublish {
          autoPublishToCharacteristics()
      } else if info.autoPublish  && !newInfo.autoPublish {
        newInfo.characteristics.forEach {
          if $0.properties.contains(.notify) || $0.properties.contains(.indicate) {
            stopPublishing($0)
          }
        }
      }
    }
  }

  // for BLE Things
  private let peripheral: BLEPeripheral?
  private var peripheralDelegate: ThingPeripheralDelegate?
  private let mqttConnector: MQTTConnecting?
  
  private var publishInterceptionQueue: DataInterceptionQueue = DataInterceptionQueue()
  private var subscribeInterceptionQueue: DataInterceptionQueue = DataInterceptionQueue()
  
  /// Initialize the Thing to be connected
  /// - Parameters:
  ///   - info: the metadata of the Thing
  public init(info: ThingInfo) {
    self.info = info
    self.peripheral = nil
    self.mqttConnector = nil
    super.init()
  }
  
  // when initializing virtual Things, we don't have access to the peripheral itself
  init(info: ThingInfo, mqttConnector: MQTTConnecting) {
    self.info = info
    self.peripheral = nil
    self.mqttConnector = mqttConnector
    super.init()
    // wait for messages from the MQTT
    self.mqttConnector?.delegate = self
  }
  
  // when initializing Bluetooth Things, we can interact with peripheral directly
  init(info: ThingInfo, peripheral: BLEPeripheral, mqttConnector: MQTTConnecting) {
    self.info = info
    self.mqttConnector = mqttConnector
    self.peripheral = peripheral
    super.init()
    // wait for messages from the MQTT
    self.mqttConnector?.delegate = self
    // wait for events on the BLE peripheral
    self.peripheralDelegate = ThingPeripheralDelegate(thing: self)
    self.peripheral?.delegate = peripheralDelegate
    // try to automatically publish all characteristics
    if self.info.autoPublish { autoPublishToCharacteristics() }
  }
  
  // auto-publish all relevant characteristics
  private func autoPublishToCharacteristics() {
    info.characteristics.forEach { characteristicInfo in
      if characteristicInfo.properties.contains(.notify) || characteristicInfo.properties.contains(.indicate) {
        readAndPublish(characteristicInfo)
      }
    }
  }
  
  // MARK: - Publish Data to the Cloud

  /// Request the data to be continuously monitored on the connected Thing and sent over to Geeny Cloud
  /// the completion block provides an opportunity to intercept and modify the data **every time** before
  /// it's pushed to the server. If you wish to omit the data to be sent, simply return nil
  /// in the completion block.
  /// A characteristic will be publishing only a single data stream. Even if readAndPublish is set multiple times,
  /// the SDK will only use the latest completion block.
  /// Note: This currently works only with Geeny-native BLE devices; in other cases please call
  /// ´publishToGeeny(data: Data, for characteristic: CharacteristicInfo)´ method
  /// - Parameters:
  ///   - characteristic: the representation of the chracteristic to be read
  ///   - keep (optional): false if publishing only once, true if publishing continuously, default is true
  ///   - completion: the callback to be executed after data is read
  public func readAndPublish(_ characteristicInfo: CharacteristicInfo, keep: Bool = true, completion: @escaping DataResult) {
    guard let peripheral = peripheral else {
      let _ = completion(Result.error(GatewayError.illegalInternalState))
      return
    }
    var publishContinuously = keep
    if !characteristicInfo.properties.contains(.notify) && !characteristicInfo.properties.contains(.indicate) {
      print("GEENY: characteristic: \(characteristicInfo.uuid) can be published only once, can't notify/indicate")
      publishContinuously = false
    }
    // if we are already continuously publishing on this characteristic, replace the previous interception
    if publishContinuously, let existingInterception  =  publishInterceptionQueue.dataInterception(for: characteristicInfo), existingInterception.reuse {
      publishInterceptionQueue.remove(with: characteristicInfo)
    }
    // the reads are asynchronous, so put it on the queue until next read
    let request = DataInterception(characteristicInfo: characteristicInfo, completion: completion, reuse: publishContinuously)
    publishInterceptionQueue.append(request)
    // activate notifications
    if publishContinuously {
      peripheral.setNotifyValue(true, for: characteristicInfo)
    } else {
      peripheral.readValue(for: characteristicInfo)
    }
  }
  
  /// A simpler version of the `Thing.readAndPublish` method above,
  /// after the data will come from the the connected Thing
  /// it will be sent continuously to the cloud without interception
  /// Note: This currently works only with Geeny-native BLE devices; in other cases please call
  /// ´publishToGeeny(data: Data, for characteristic: CharacteristicInfo)´ method
  /// - Parameters:
  ///   - characteristic: the representation of the characteristic to publish
  public func readAndPublish(_ characteristicInfo: CharacteristicInfo) {
    self.readAndPublish(characteristicInfo) { result in
      switch result {
      case .success(let data):
        return data
      case .error(let e):
        print("MQTT: readAndPublish Error \(e.localizedDescription)")
        // TODO: marshal the reading errors to the Gateway so the developers can respond
        return nil
      }
    }
  }
  
  /// Stop publishing the device data
  /// stop sending the data for the given characteristic to the cloud
  /// - Parameters:
  ///   - characteristic: the representation of the characteristic to be read
  public func stopPublishing(_ characteristicInfo: CharacteristicInfo) {
    publishInterceptionQueue.remove(with: characteristicInfo)
    guard let peripheral = peripheral else {
      return
    }
    peripheral.setNotifyValue(false, for: characteristicInfo)
  }
  
  // MARK: - Subscribe to incoming Data from the Cloud
  /// Subscribe to the relevant data coming from the Geeny Cloud
  /// the completion block provides an opportunity to inspect or enrich the data **every time** before
  /// it's pushed to the Thing. If you wish to omit the data to be sent, simply return nil
  /// in the completion block.
  /// - Parameters:
  ///   - characteristic: the representation of the chracteristic to be read
  ///   - completion: the callback to be executed after receiving data from the Cloud
  public func subscribe(to characteristicInfo: CharacteristicInfo, completion: @escaping DataResult) {

    guard let mqttConnector = mqttConnector else {
      assert(false)
      return
    }

    let request = DataInterception(characteristicInfo: characteristicInfo, completion: completion, reuse: true)
    subscribeInterceptionQueue.append(request)

    mqttConnector.connect { status in
      switch status {
      case .connected:
        let topic = characteristicInfo.topic
        mqttConnector.subscribe(toTopic: topic)
        print("GEENY MQTT: subscribed to \(topic)")
      case .error(MQTTError.connectionError):
        print("MQTT: Connection Error")
      // TODO: marshal the connection errors to the Gateway so the developers can react?
      case .error(MQTTError.protocolError):
        print("MQTT: Protocol version Error")
      default:
        break
      }
    }
  }

  /// A simpler version of the `Thing.subscribe` method above,
  /// after the data will come from the the Cloud
  /// it will be sent automatically to the Thing without interception
  /// - Parameters:
  ///   - characteristic: the representation of the characteristic to notified about
  public func subscribe(to characteristicInfo: CharacteristicInfo) {
    self.subscribe(to: characteristicInfo) { result in
      switch result {
      case .success(let data):
        return data
      case .error(let e):
        print("MQTT: Subscription Error \(e.localizedDescription)")
        // TODO: marshal the reading errors to the Gateway so the developers can respond
        return nil
      }
    }
  }

  /// Unsubscribe
  /// stop receiving the data for the given characteristic from the cloud
  /// - Parameters:
  ///   - characteristic: the representation of the characteristic to be read
  public func unsubscribe(to characteristicInfo: CharacteristicInfo) {

    guard let mqttConnector = mqttConnector else {
      assert(false)
      return
    }

    subscribeInterceptionQueue.remove(with: characteristicInfo)

    mqttConnector.connect { status in
      switch status {
      case .connected:
        let topic = characteristicInfo.topic
        mqttConnector.unsubscribe(fromTopic: topic)
        print("GEENY MQTT: unsubscribed from \(topic)")
      case .error(MQTTError.connectionError):
        print("MQTT: Connection Error")
      // TODO: marshal the connection errors to the Gateway so the developers can react?
      case .error(MQTTError.protocolError):
        print("MQTT: Protocol version Error")
      default:
        break
      }
    }
  }
  
  // MARK: - MQTT
  /// Send data to Geeny Cloud directly
  /// If you wish to send data to the cloud manually. This is quite useful in cases when you already have integrated
  /// your Bluetooth device in your app.
  /// - Parameters:
  ///   - data: data object to be sent
  ///   - characteristicInfo: characteristic that the data belongs to
  public func publishToGeeny(data: Data, characteristicInfo: CharacteristicInfo) {

    guard let mqttConnector = mqttConnector else {
      assert(false)
      return
    }
    
    mqttConnector.connect { status in
      switch status {
      case .connected:
        let topic = characteristicInfo.topic
        mqttConnector.publishData(data, onTopic: topic)
        print("GEENY MQTT: published on \(topic) - data:\(data.geenyHexEncodedString())")
      case .error(MQTTError.connectionError):
        print("MQTT: Connection Error")
      // TODO: marshal the connection errors to the Gateway so the developers can react?
      case .error(MQTTError.protocolError):
        print("MQTT: Protocol version Error")
      default:
        break
      }
    }
  }
  
  // MARK: - Write to Thing
  /// Write data to Thing directly, eg. over Bluetooth connection
  /// - Parameters:
  ///   - data: data to be sent
  ///   - characteristicInfo: characteristic that the data belongs to
  public func writeToThing(data: Data, characteristicInfo: CharacteristicInfo) {
    guard let peripheral = peripheral else {
      return
    }
    if characteristicInfo.properties.contains(.write) {
      peripheral.writeValue(data, for: characteristicInfo)
    } else {
      print("GEENY Error: The characteristic \(characteristicInfo.uuid) is not write-enabled")
    }
  }

  
  // process the data that comes from the Thing, e.g. over BLE
  internal func onDataFromThing(characteristicInfo: CharacteristicInfo, data: Data?, error: Error?) {
    // Check if the developer is still publishing this characteristic
    guard let interception  =  publishInterceptionQueue.dataInterception(for: characteristicInfo) else {
      return
    }
    // Remove the request from the read queue (they are one-offs)
    if !interception.reuse {
      publishInterceptionQueue.remove(with: characteristicInfo)
    }
    
    if let data = data {
      if let processedData = interception.completion(Result.success(data)) {
        publishToGeeny(data: processedData, characteristicInfo: interception.characteristicInfo)
      }
    } else if let error = error {
      let _ = interception.completion(Result.error(error))
    }
  }

  // process the data coming from the cloud
  internal func onDataFromCloud(_ data: Data, onTopic topic: String) {
    // Check whether there is an active subscription to this characteristic
    guard let interception  =  subscribeInterceptionQueue.dataInterception(for: topic) else {
      return
    }
    if let processedData = interception.completion(Result.success(data)) {
      writeToThing(data: processedData, characteristicInfo: interception.characteristicInfo)
    }
  }

}

// we prefer not to expose the BLE delegate handlers
// so ThingPeripheralDelegate is defined in an internal class
private class ThingPeripheralDelegate: NSObject, CBPeripheralDelegate {
  
  weak var thing: Thing?
  
  init(thing: Thing) {
    self.thing = thing
    super.init()
  }
  // every time a BLE device will get data from some characteristic, it will pass it up to the Thing
  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    assert(thing != nil)
    guard let characteristicInfo = thingCharacteristicInfo(for: characteristic.uuid) else {
      print("GEENY Error: The characteristic \(characteristic.uuid.uuidString) is not associated with \(String(describing: thing!.info.name))")
      return
    }
    thing?.onDataFromThing(characteristicInfo: characteristicInfo, data: characteristic.value, error: error)
  }
  // find the matching CharacteristicInfo for the BLE characteristic
  func thingCharacteristicInfo(for identifier: CBUUID) -> CharacteristicInfo? {
    return thing?.info.characteristics.filter { $0.uuid == identifier.uuidString }.first
  }

}
