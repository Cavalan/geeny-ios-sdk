//
//  ThingTests.swift
//  GeenyGatewayTests
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import XCTest
import CoreBluetooth
@testable import GeenyGateway

class ThingTests: XCTestCase {
    
  override func setUp() {
      super.setUp()
  }
  
  override func tearDown() {
      super.tearDown()
  }
    
  
  func testThing_readSingle() {
    
    let testExpectation = expectation(description: "Reading from single BLE characteristic succeeds and result is passed on")
    
    // prepare the mocked BLE Thing
    let (thingInfo, peripheral, mqttConnector) = thingMocks()
    let thing = Thing(info: thingInfo, peripheral: peripheral, mqttConnector: mqttConnector)
    // choose one of the characteristics
    let characteristicInfo = thingInfo.characteristics[0]

    thing.readAndPublish(characteristicInfo) { result in
      switch result {
      case .success(let data):
        XCTAssertEqual(data, Data([0x0022]))
        testExpectation.fulfill()
        return data
      case .error(let e):
        XCTAssert(false)
        return nil
      }
    }
    // simulate the BLE periperal delivering the characteristic value
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.3, execute: {
      thing.onDataFromThing(characteristicInfo: characteristicInfo, data: Data([0x0022]), error: nil)
    })
    
    
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  func testThing_readMultiple() {
    let testExpectation = expectation(description: "Reading from multiple BLE characteristics succeeds and result is passed on")
    
    // prepare the mocked BLE Thing
    let (thingInfo, peripheral, mqttConnector) = thingMocks()
    let thing = Thing(info: thingInfo, peripheral: peripheral, mqttConnector: mqttConnector)
    // choose one of the characteristics
    let characteristicInfo0 = thingInfo.characteristics[0]
    let characteristicInfo1 = thingInfo.characteristics[1]

    // the first publish
    thing.readAndPublish(characteristicInfo0) { result in
      switch result {
      case .success(let data):
        XCTAssertEqual(data, Data([0x0022]))
        return data
      case .error(let e):
        XCTAssert(false)
        return nil
      }
    }
    // and immediately the second publish, before the result of the first read are there
    thing.readAndPublish(characteristicInfo1) { result in
      switch result {
      case .success(let data):
        XCTAssertEqual(data, Data([0x0026]), "The second read gets also the second data, in the right block")
        testExpectation.fulfill()
        return data
      case .error(let e):
        XCTAssert(false, "Unexpected BLE read error")
        return nil
      }
    }
    
    // the first peripheral read delivers data first
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.3, execute: {
      thing.onDataFromThing(characteristicInfo: characteristicInfo0, data: Data([0x0022]), error: nil)
    })
    
    // the second read delivers data a bit later
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.6, execute: {
      thing.onDataFromThing(characteristicInfo: characteristicInfo1, data: Data([0x0026]), error: nil)
    })

    waitForExpectations(timeout: 1.5, handler: nil)
  }
  
  func testThing_readAndPassToMQTT() {
    let testExpectation = expectation(description: "Developer reads data from the Thing; the data is automatically sent to the Cloud")
    
    // prepare the mocked BLE Thing
    let (thingInfo, peripheral, mqttConnector) = thingMocks()
    let thing = Thing(info: thingInfo, peripheral: peripheral, mqttConnector: mqttConnector)
    // choose one of the characteristics
    let characteristicInfo = thingInfo.characteristics[0]

    // initiate reading without any options
    thing.readAndPublish(characteristicInfo)
  
    // the mqtt is sending the data over
    mqttConnector.onPublishData = {data, topic in
      XCTAssertEqual(data, Data([0x0022]), "the correct data was sent to MQTT")
      XCTAssertEqual(topic, "2a29", "the topic is identical with characteristic of the peripheral")
      testExpectation.fulfill()
    }
    
    // simulate BLE device responding to read request
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.3, execute: {
      thing.onDataFromThing(characteristicInfo: characteristicInfo, data: Data([0x0022]), error: nil)
    })
    
    
    waitForExpectations(timeout: 0.5, handler: nil)
  }
  
  func testThing_readAlterAndPassToMQTT() {
    let testExpectation = expectation(description: "Developer reads and alters the data before sending to Geeny")
    
    // prepare the mocked BLE Thing
    let (thingInfo, peripheral, mqttConnector) = thingMocks()
    let thing = Thing(info: thingInfo, peripheral: peripheral, mqttConnector: mqttConnector)
    // choose one of the characteristics
    let characteristicInfo = thingInfo.characteristics[0]

    // initiate reading
    thing.readAndPublish(characteristicInfo) { result in
      switch result {
      case .success(let data):
        XCTAssertEqual(data, Data([0x0022]), "developers get to inspect the data before going to Geeny")
        // let's say they alter the data
        return Data([0x0030])
      case .error(let e):
        XCTAssert(false)
        return nil
      }
    }

    mqttConnector.onPublishData = {data, topic in
      XCTAssertEqual(data, Data([0x0030]), "the altered data was sent over MQTT")
      XCTAssertEqual(topic, "2a29", "the topic is identical with characteristic of the peripheral")
      testExpectation.fulfill()
    }
    
    // simulate BLE device responding to read request
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.3, execute: {
      thing.onDataFromThing(characteristicInfo: characteristicInfo, data: Data([0x0022]), error: nil)
    })
  
    
    waitForExpectations(timeout: 0.5, handler: nil)
  }
  
  func testThing_readPreventSendingToMQTT() {
    let testExpectation = expectation(description: "Developer has decided NOT to send data afer inspecting it")
    
    // prepare the mocked BLE Thing
    let (thingInfo, peripheral, mqttConnector) = thingMocks(characteristicProperty: .notify, autoPublish: true)
    let thing = Thing(info: thingInfo, peripheral: peripheral, mqttConnector: mqttConnector)
    // choose one of the characteristics
    let characteristicInfo = thingInfo.characteristics[0]

    // initiate reading
    thing.readAndPublish(characteristicInfo) { result in
      switch result {
      case .success(let data):
        XCTAssertEqual(data, Data([0x0022]), "developers get to inspect the data before going to Geeny")
        // and they decide not to send the data!
        return nil
      case .error(let e):
        XCTAssert(false, "Unexpected BLE read error")
        return nil
      }
    }
    
    mqttConnector.onPublishData = {data, topic in
      XCTAssert(false, "it should have not been sent to MQTT!")
    }
    
    // simulate BLE device responding to read request
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.2, execute: {
      thing.onDataFromThing(characteristicInfo: characteristicInfo, data: Data([0x0022]), error: nil)
    })
    
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.3, execute: {
      // if not failed until now, means we have passed
      testExpectation.fulfill()
    })
    
    
    waitForExpectations(timeout: 0.4, handler: nil)
  }
  
  
  func testThing_readPublishToMQTT() {
    let testExpectation = expectation(description: "Developer publishes a BLE characteristic that provides data to be sent to the Cloud regularly")
    
    // prepare the mocked BLE Thing with a notifying characteristic
    let (thingInfo, peripheral, mqttConnector) = thingMocks(characteristicProperty: .notify, autoPublish: false)
    let thing = Thing(info: thingInfo, peripheral: peripheral, mqttConnector: mqttConnector)
    // choose one of the characteristics
    let characteristicInfo = thingInfo.characteristics[0]
    // start publishing without any options
    thing.readAndPublish(characteristicInfo)
    
    var readsCount = 0
    // the mqtt is sending the data over
    mqttConnector.onPublishData = {data, topic in
      readsCount += 1
      if readsCount == 1 {
        XCTAssertEqual(data, Data([0x0021]), "the correct data was sent to MQTT - 1")
      } else if readsCount == 2 {
        XCTAssertEqual(data, Data([0x0022]), "the correct data was sent to MQTT - 2")
      } else if readsCount == 3 {
        XCTAssertEqual(data, Data([0x0023]), "the correct data was sent to MQTT - 3")
        testExpectation.fulfill()
      }
    }
    
    // simulate BLE device sending notifications
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.01, execute: {
      thing.onDataFromThing(characteristicInfo: characteristicInfo, data: Data([0x0021]), error: nil)
    })
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.02, execute: {
      thing.onDataFromThing(characteristicInfo: characteristicInfo, data: Data([0x0022]), error: nil)
    })
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.03, execute: {
      thing.onDataFromThing(characteristicInfo: characteristicInfo, data: Data([0x0023]), error: nil)
    })
    
    
    waitForExpectations(timeout: 0.1, handler: nil)
  }
  
  func testThing_subscribeAndInterceptMQTT() {
    let testExpectation = expectation(description: "Developer subscribes to a certain MQTT topic on the Cloud and receives commands intended for the Thing")
    
    // prepare the mocked BLE Thing with a notifying characteristic
    let (thingInfo, peripheral, mqttConnector) = thingMocks(characteristicProperty: .notify, autoPublish: true)
    let thing = Thing(info: thingInfo, peripheral: peripheral, mqttConnector: mqttConnector)
    // choose one of the characteristics
    let characteristicInfo = thingInfo.characteristics[0]
    
    thing.subscribe(to: characteristicInfo) { result in
      switch result {
      case .success(let data):
        XCTAssertEqual(data, Data([0x0021]), "developers get to inspect the data before sending to Thing")
        testExpectation.fulfill()
        return data
      case .error(let e):
        XCTAssert(false, "Unexpected MQTT read error")
        return nil
      }
    }
    
    
    // data is received from the cloud via the MQTT
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.01, execute: {
      mqttConnector.delegate?.onDataFromCloud(Data([0x0021]), onTopic: characteristicInfo.topic)
    })
    waitForExpectations(timeout: 0.3, handler: nil)
  }

  func testThing_autoPublishOn() {
    let testExpectation = expectation(description: "publish notifying characteristic automatically")
    
    // prepare the mocked BLE Thing with a inidcating characteristic
    let (thingInfo, peripheral, mqttConnector) = thingMocks(characteristicProperty: [.read, .indicate], autoPublish: true)
    let thing = Thing(info: thingInfo, peripheral: peripheral, mqttConnector: mqttConnector)
    // choose one of the characteristics
    let characteristicInfo = thingInfo.characteristics[0]

    // the mqtt is sending the data ostatusver automatically
    mqttConnector.onPublishData = {data, topic in
      XCTAssertEqual(data, Data([0x0021]), "the correct data was sent to MQTT - 1")
      testExpectation.fulfill()
    }
    
    // simulate BLE device sending notifications
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.01, execute: {
      thing.onDataFromThing(characteristicInfo: characteristicInfo, data: Data([0x0021]), error: nil)
    })
    
    waitForExpectations(timeout: 0.1, handler: nil)
  }
  
  func testThing_autoPublishOff() {
    let testExpectation = expectation(description: "do not publish notifying characteristics automatically")
    
    // prepare the mocked BLE Thing with a notifying characteristic
    let (thingInfo, peripheral, mqttConnector) = thingMocks(characteristicProperty: [.read, .notify], autoPublish: false)
    let thing = Thing(info: thingInfo, peripheral: peripheral, mqttConnector: mqttConnector)
    // choose one of the characteristics
    let characteristicInfo = thingInfo.characteristics[0]

    
    // the mqtt is sending the data over automatically
    mqttConnector.onPublishData = {data, topic in
      XCTAssert(false, "the data should not have been sent to MQTT - 1")
    }
    
    // simulate BLE device sending notifications
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.01, execute: {
      thing.onDataFromThing(characteristicInfo: characteristicInfo, data: Data([0x0021]), error: nil)
    })
    // complete the test if no data was sent
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.02, execute: {
      testExpectation.fulfill()
    })
    waitForExpectations(timeout: 0.3, handler: nil)
  }
  
  
  func testThing_publishMQTTMultiple() {
    let testExpectation = expectation(description: "Developer publishes multiple BLE characteristics that send data to the Cloud regularly")
    
    // prepare the mocked BLE Thing with a indicating characteristic
    let (thingInfo, peripheral, mqttConnector) = thingMocks(characteristicProperty: [.read, .indicate])
    let thing = Thing(info: thingInfo, peripheral: peripheral, mqttConnector: mqttConnector)
    // choose one of the characteristics
    let characteristicInfo0 = thingInfo.characteristics[0]
    // additional characteristic
    let characteristicInfo1 = thingInfo.characteristics[1]

    
    var readsCount = 0
    // the mqtt is sending the data over
    mqttConnector.onPublishData = {data, topic in
      readsCount += 1
      if readsCount == 1 {
        XCTAssertEqual(topic, "2a29", "the correct topic was sent to MQTT - 1")
        XCTAssertEqual(data, Data([0x0021]), "the correct data was sent to MQTT - 1")
      } else if readsCount == 2 {
        XCTAssertEqual(topic, "2a30", "the correct topic was sent to MQTT - 2")
        XCTAssertEqual(data, Data([0x0022]), "the correct data was sent to MQTT - 2")
      } else if readsCount == 3 {
         XCTAssertEqual(topic, "2a29", "the correct topic was sent to MQTT - 3")
        XCTAssertEqual(data, Data([0x0023]), "the correct data was sent to MQTT - 3")
        testExpectation.fulfill()
      }
    }
    
    // simulate BLE device sending notifications
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.01, execute: {
      thing.onDataFromThing(characteristicInfo: characteristicInfo0, data: Data([0x0021]), error: nil)
    })
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.02, execute: {
      thing.onDataFromThing(characteristicInfo: characteristicInfo1, data: Data([0x0022]), error: nil)
    })
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.03, execute: {
      thing.onDataFromThing(characteristicInfo: characteristicInfo0, data: Data([0x0023]), error: nil)
    })

    
    waitForExpectations(timeout: 0.3, handler: nil)
  }
  
  func testThing_writeToThing() {
    let testExpectation = expectation(description: "Developer sends a command directly to the Thing over BLE")
    
    // prepare the mocked BLE Thing with a indicating characteristic
    let (thingInfo, peripheral, mqttConnector) = thingMocks(characteristicProperty: [.write, .read])
    let thing = Thing(info: thingInfo, peripheral: peripheral, mqttConnector: mqttConnector)
    // choose one of the characteristics
    let characteristicInfo0 = thingInfo.characteristics[0]
    // Developer writes data to the Thing
    thing.writeToThing(data: Data([0x0023]), characteristicInfo: characteristicInfo0)
    
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.01, execute: {
      let mockPeripheral = peripheral as! MockPeripheral
      XCTAssertEqual(mockPeripheral.lastWrittenData, Data([0x0023]), "correct data was written")
      XCTAssertEqual(mockPeripheral.lastWrittenCharacteristic?.uuid, characteristicInfo0.uuid, "to the correct characteristic")
      testExpectation.fulfill()
    })
    waitForExpectations(timeout: 0.2, handler: nil)
  }
  
  func testThing_virtualThing() {
    let testExpectation = expectation(description: "Developer connects a virtual Thing to the Cloud")
    let characteristicInfo0 = CharacteristicInfo(uuid: "2a29", description: "antigravity sensor", topic: "2a29", properties: [.read, .notify])
    let characteristicInfo1 = CharacteristicInfo(uuid: "2a30", description: "force field detector", topic: "2a30", properties: [.write])
    let geenyInfo = GeenyThingInfo(protocolVersion: 1, serialNumber: "dsaas348432", thingType: "0569ABDB-7A32-46C6-B8DC-797A326E922A")
    let thingInfo = ThingInfo(family: .virtualThing, name:"Virtual Ship", peripheralId: "0569ABDA-7A32-46C6-B8DC-797A326E922A", geenyThingInfo: geenyInfo, characteristics: [characteristicInfo0, characteristicInfo1], autoPublish: false)
    let mqttConnector = MockMQTTConnector()
    let thing = Thing(info: thingInfo, mqttConnector: mqttConnector)

    // the mqtt is sending the data over
    mqttConnector.onPublishData = {data, topic in
        XCTAssertEqual(topic, "2a29", "the correct topic was sent from virtual thing to MQTT")
        XCTAssertEqual(data, Data([0x0021]), "the correct data was sent from virtual thing to MQTT")
    }

    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.01, execute: {
      // developer publishes data directly to the Cloud
      thing.publishToGeeny(data: Data([0x0021]), characteristicInfo: characteristicInfo0)
    })

    thing.subscribe(to: characteristicInfo1) { result in
      switch result {
      case .success(let data):
        XCTAssertEqual(data, Data([0x0024]), "developers get to inspect the data and route it to their device")
        testExpectation.fulfill()
        return data
      case .error(let e):
        XCTAssert(false, "Unexpected MQTT read error")
        return nil
      }
    }


    // data is received from the cloud via the MQTT
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.02, execute: {
      mqttConnector.delegate?.onDataFromCloud(Data([0x0024]), onTopic: characteristicInfo1.topic)
    })

    waitForExpectations(timeout: 0.3, handler: nil)
  }
  
  // create a few mocks at the same time
  fileprivate func thingMocks(characteristicProperty: CharacteristicProperties = .read, autoPublish: Bool = true ) -> (ThingInfo, BLEPeripheral, MockMQTTConnector) {
    let peripheral = MockPeripheral(name: "test1", identifier: UUID(uuidString: "5D0349E6-0AC2-444F-97F6-0350957B8002")!, state: .disconnected)
    let characteristicInfo0 = CharacteristicInfo(uuid: "2a29", description: "antigravity sensor", topic: "2a29", properties: characteristicProperty)
    let characteristicInfo1 = CharacteristicInfo(uuid: "2a30", description: "force field detector", topic: "2a30", properties: characteristicProperty)
    let thingInfo = ThingInfo(family: .physicalThing, name: peripheral.name, peripheralId: peripheral.identifier.uuidString, geenyThingInfo: nil, characteristics: [characteristicInfo0, characteristicInfo1], autoPublish: autoPublish)
    let mqttConnector = MockMQTTConnector()
    
    return (thingInfo, peripheral, mqttConnector)
  }
  
}

fileprivate class MockMQTTConnector: MQTTConnecting {

  var delegate: MQTTConnectingDelegate?
  
  var onPublishData: ((Data, String) -> ())?

  func connect(statusBlock: @escaping MQTTConnecting.MQTTStatusBlockType) {
    statusBlock(.connected)
  }
  func disconnect() { }
  func publishString(_ text: String, onTopic topic: String) { }
  func publishData(_ data: Data, onTopic topic: String) {
    self.onPublishData?(data, topic)
  }
  func subscribe(toTopic topic: String) { }
  func unsubscribe(fromTopic topic: String) { }
}



