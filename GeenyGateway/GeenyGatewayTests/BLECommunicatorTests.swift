//
//  BLECommunicatorTests.swift
//  GeenyGatewayTests
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import XCTest
@testable import GeenyGateway

class BLECommunicatorTests: XCTestCase {
  
  private var centralManager: MockCentralManager!
  private var sut: BLECommunicator!
  
  private let standardPeripherals = [
    MockPeripheral(name: "test1", identifier: UUID(uuidString: "5D0349E6-0AC2-444F-97F6-0350957B8002")!, state: .disconnected),
    MockPeripheral(name: "test2", identifier: UUID(uuidString: "76E53DAF-02B9-4A63-9952-C2FC6810B263")!, state: .disconnected)
  ]
  
  override func setUp() {
    super.setUp()
    
    centralManager = MockCentralManager()
    sut = BLECommunicator(centralManager: centralManager)
  }
  
  func testScan_succeedsAlreadyPoweredOn() {
    let testExpectation = expectation(description: "Scan succeeds, CentralManager already poweredOn")
    
    centralManager.state = .poweredOn
    let peripherals = standardPeripherals
    centralManager.peripherals = peripherals
    
    sut.scanForThings(timeout: 0.1) { (result) in
      switch result {
      case .success(let basics):
        XCTAssertEqual(basics.count, peripherals.count)
        for peripheral in peripherals {
          XCTAssertTrue(basics.contains(where: {
            return $0.name == peripheral.name &&
              $0.peripheralId == peripheral.identifier.uuidString
          }))
        }
        testExpectation.fulfill()
      case .error:
        XCTAssert(false)
      }
    }
    
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  func testScan_succeedsPoweredOnLater() {
    let testExpectation = expectation(description: "Scan succeeds, CentralManager poweredOn later")
    
    centralManager.state = .unknown
    let peripherals = standardPeripherals
    centralManager.peripherals = peripherals
    
    sut.scanForThings(timeout: 0.2) { (result) in
      switch result {
      case .success(let basics):
        XCTAssertEqual(basics.count, peripherals.count)
        for peripheral in peripherals {
          XCTAssertTrue(basics.contains(where: {
            return $0.name == peripheral.name &&
              $0.peripheralId == peripheral.identifier.uuidString
          }))
        }
        testExpectation.fulfill()
      case .error:
        XCTAssert(false)
      }
    }
    
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1) {
      self.centralManager.state = .poweredOn
    }
    
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  func testScan_failsBusy() {
    let firstScanExpectation = expectation(description: "First scan should succeed")
    let secondScanExpectation = expectation(description: "Second scan should fail")
    
    centralManager.state = .poweredOn
    let peripherals = standardPeripherals
    centralManager.peripherals = peripherals
    
    sut.scanForThings(timeout: 0.2) { (result) in
      switch result {
      case .success:
        firstScanExpectation.fulfill()
      case .error:
        XCTAssert(false)
      }
    }
    
    sut.scanForThings(timeout: 0.1) { (result) in
      switch result {
      case .success:
        XCTAssert(false)
      case .error:
        secondScanExpectation.fulfill()
      }
    }
    
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  func testScan_failsAlreadyPoweredOff() {
    let testExpectation = expectation(description: "Scan fails because Bluetooth is turned off")
    
    centralManager.state = .poweredOff
    centralManager.peripherals = standardPeripherals
    
    sut.scanForThings(timeout: 0.1) { (result) in
      switch result {
      case .success:
        XCTAssert(false)
      case .error:
        XCTAssert(true)
        testExpectation.fulfill()
      }
    }
    
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  func testScan_failsPoweredOffLater() {
    let testExpectation = expectation(description: "Scan fails because Bluetooth is turned off")
    
    centralManager.state = .unknown
    centralManager.peripherals = standardPeripherals
    
    sut.scanForThings(timeout: 0.3) { (result) in
      switch result {
      case .success:
        XCTAssert(false)
      case .error:
        XCTAssert(true)
        testExpectation.fulfill()
      }
    }
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1) {
      self.centralManager.state = .poweredOff
    }
    
    // Should fail immediately after state change, before the wait timeout.
    waitForExpectations(timeout: 0.2, handler: nil)
  }
  
  func testConnectToPeripheral_failsTooBusy() {
    let testExpectation = expectation(description: "Connection fails because connecting to too many at the same time")
    
    centralManager.peripherals = standardPeripherals
    
    let peripheralId0 = standardPeripherals[0].identifier.uuidString
    let peripheralId1 = standardPeripherals[1].identifier.uuidString
    
    sut.connectToPeripheral(withIdentifier: peripheralId0) { result in }
    // trying to connect immediately to a second one after initiating the first
    sut.connectToPeripheral(withIdentifier: peripheralId1) { result in
      switch result {
      case .error(let e):
        XCTAssertEqual(e.localizedDescription, GatewayError.busyPleaseRetryLater.localizedDescription)
        testExpectation.fulfill()
      case .success(_):
        XCTAssert(false)
      }
    }
    
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  
  func testConnectToPeripheral_failsWrongIdentifier() {
    let testExpectation = expectation(description: "Connection fails because providing wrong identifier")
    
    
    let nonUUIDStringIdentifier = "234f02203ae20334223"
    
    // trying to connect to a non-standard identifier
    sut.connectToPeripheral(withIdentifier: nonUUIDStringIdentifier) { result in
      switch result {
      case .error(let e):
        XCTAssertEqual(e.localizedDescription, GatewayError.invalidUUIDString.localizedDescription)
        testExpectation.fulfill()
      case .success(_):
        XCTAssert(false)
      }
    }
    
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  func testConnectToPeripheral_reconnectionIsControllable() {
    let testExpectation = expectation(description: "The connection should be cancellable")
    // make sure the BLE is 'on' so the connection events are simulated
    centralManager.state = .poweredOn
    centralManager.peripherals = standardPeripherals
    let peripheralId0 = standardPeripherals[0].identifier.uuidString
    
    var progress = sut.connectToPeripheral(withIdentifier: peripheralId0) { result in }
    //
    progress.cancel()
    
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.5) {
      // trying to connect to the same Thing
      // after canceling the first connection attempt
      progress = self.sut.connectToPeripheral(withIdentifier: peripheralId0) { result in
        switch result {
        case .error(let e):
          XCTAssert(false, "The second connection failed")
        case .success(_):
          XCTAssert(true, "it should be possible to cancel the reconnection process and start next one")
          testExpectation.fulfill()
        }
      }
      
    }

    waitForExpectations(timeout: 2, handler: nil)
  }
  
}
