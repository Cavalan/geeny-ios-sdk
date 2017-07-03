//
//  StringExtensionTests.swift
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

class StringExtensionTests: XCTestCase {
  
  // MARK: UUID
  
  func testUUID_validInput() {
    // 32 characters
    let input = "123E4567E89B12D3A456426655440000"
    let expectedOutput = "123E4567-E89B-12D3-A456-426655440000"
    XCTAssertEqual(input.geenyUUIDFormatted(), expectedOutput)
  }
  
  func testUUID_emptyInput() {
    let input = ""
    let expectedOutput = ""
    XCTAssertEqual(input.geenyUUIDFormatted(), expectedOutput)
  }
  
  func testUUID_inputTooShort() {
    // 30 characters
    let input = "123E4567E89B12D3A4564266554400"
    let expectedOutput = "123E4567E89B12D3A4564266554400"
    XCTAssertEqual(input.geenyUUIDFormatted(), expectedOutput)
  }

  func testUUID_inputTooLong() {
    // 36 characters
    let input = "123E4567E89B12D3A4564266554400001111"
    let expectedOutput = "123E4567E89B12D3A4564266554400001111"
    XCTAssertEqual(input.geenyUUIDFormatted(), expectedOutput)
  }
  
}
