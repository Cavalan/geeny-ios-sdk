//
//  GeenyThingInfoTests.swift
//  GeenyGateway
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import XCTest
@testable import GeenyGateway

class GeenyThingInfoTests: XCTestCase {
  
  func testDecodeThingInfo_success1() {
    guard let dataURL = Bundle(for: GeenyThingInfoTests.self).url(forResource: "geenyThingInfo1.binary", withExtension: nil) else {
      XCTAssert(false)
      return
    }
    
    do {
      let data = try Data(contentsOf: dataURL)
      let info = GeenyThingInfoParser.parseData(data)
      XCTAssertNotNil(info)
      if let info = info {
        XCTAssertEqual(info.protocolVersion, 1)
        XCTAssertEqual(info.serialNumber, "00010203-0405-0607-0809-0A0B0C0D0E0F")
        XCTAssertEqual(info.thingType, "00112233-4455-6677-8899-AABBCCDDEEFF")
      }
    } catch {
      XCTAssert(false)
    }
  }
  
  func testDecodeThingInfo_success2() {
    guard let dataURL = Bundle(for: GeenyThingInfoTests.self).url(forResource: "geenyThingInfo2.binary", withExtension: nil) else {
      XCTAssert(false)
      return
    }
    
    do {
      let data = try Data(contentsOf: dataURL)
      let info = GeenyThingInfoParser.parseData(data)
      XCTAssertNotNil(info)
      if let info = info {
        XCTAssertEqual(info.protocolVersion, 1)
        XCTAssertEqual(info.serialNumber, "00102030-4050-6070-8090-A0B0C0D0E0F0")
        XCTAssertEqual(info.thingType, "F0E1D2C3-B4A5-9687-7869-5A4B3C2D1E0F")
      }
    } catch {
      XCTAssert(false)
    }
  }
  
  func testDecodeThingInfo_wrongDataLength() {
    let data = "abc".data(using: .utf8)!
    let info = GeenyThingInfoParser.parseData(data)
    XCTAssertNil(info)
  }
  
  func testDecodeThingInfo_wrongVersion() {
    guard let dataURL = Bundle(for: GeenyThingInfoTests.self).url(forResource: "geenyThingInfo_invalidVersion.binary", withExtension: nil) else {
      XCTAssert(false)
      return
    }
    
    do {
      let data = try Data(contentsOf: dataURL)
      let info = GeenyThingInfoParser.parseData(data)
      XCTAssertNil(info)
    } catch {
      XCTAssert(false)
    }
  }
  
}
