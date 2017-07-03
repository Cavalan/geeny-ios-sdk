//
//  ThingCreatorTests.swift
//  GatewayTests
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import XCTest
import RxSwift
import OHHTTPStubs
@testable import GeenyGateway

class ThingCreatorTests: XCTestCase {
  
  private var creator: ThingCreator!
  private let disposeBag = DisposeBag()

  override func setUp() {
    super.setUp()
    creator = ThingCreator()
  }
  
  private func postThingCondition() -> OHHTTPStubsTestBlock {
    return isMethodPOST() && isHost(Endpoint.thingManagerHost) && isPath(ThingCreator.Constants.path)
  }
  
  func testCreateThing_success() {
    let testExpectation = expectation(description: "Successfully creates new thing")

    stub(condition: postThingCondition()) { request -> OHHTTPStubsResponse in
      let path = OHPathForFile("post-thing-201.json", ThingCreatorTests.self)!
      return fixture(filePath: path, status: 201, headers: nil)
    }
    
    let token = "eyJhbGciOi_validtoken"
    let name = "goodThing"
    let serialNumber = "b9e05f7a-7249-4406-a4de-579ffa3bfc22"
    let thingType = "1da44921-eacd-45ec-be97-d01a81d8b92c"
    creator.create(token: token, name: name, serialNumber: serialNumber, thingTypeId: thingType)
      .subscribe { event in
        switch event {
        case .next(let response):
          XCTAssertFalse(response.thingId.isEmpty)
          XCTAssertEqual(response.thingName, name)
          XCTAssertEqual(response.serialNumber, serialNumber)
          XCTAssertEqual(response.thingType, thingType)
          XCTAssertEqual(response.created, TestConstants.defaultTimestamp)
          
          XCTAssertFalse(response.certs.caCertificate.isEmpty)
          XCTAssertFalse(response.certs.clientCertificate.isEmpty)
          XCTAssertFalse(response.certs.privateKey.isEmpty)
        case .error:
          XCTAssert(false)
        case .completed:
          testExpectation.fulfill()
        }
      }
      .addDisposableTo(disposeBag)
    
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  func testCreateThing_invalidThingTypeId() {
    let testExpectation = expectation(description: "Fails because the given thingTypeId is invalid")
    
    stub(condition: postThingCondition()) { request -> OHHTTPStubsResponse in
      let path = OHPathForFile("post-thing-400.json", ThingCreatorTests.self)!
      return fixture(filePath: path, status: 400, headers: nil)
    }
    
    let token = "eyJhbGciOi_validtoken"
    let name = "goodThing"
    let serialNumber = "b9e05f7a-7249-4406-a4de-579ffa3bfc22"
    let thingTypeId = "711b4ef6-527a-11e7-blah"
    creator.create(token: token, name: name, serialNumber: serialNumber, thingTypeId: thingTypeId)
      .subscribe { event in
        switch event {
        case .next:
          XCTAssert(false)
        case .error:
          testExpectation.fulfill()
        case .completed:
          XCTAssert(false)
        }
      }
      .addDisposableTo(disposeBag)
    
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  // Disabled before server authentication is done.
  func testCreateThing_invalidToken() {
    let testExpectation = expectation(description: "Fails because of invalid token")
    
    stub(condition: postThingCondition()) { request -> OHHTTPStubsResponse in
      let path = OHPathForFile("post-401.json", ThingCreatorTests.self)!
      return fixture(filePath: path, status: 401, headers: nil)
    }
    
    let token = "eyJhbGciOi_badtoken"
    let name = "goodThing"
    let serialNumber = "b9e05f7a-7249-4406-a4de-579ffa3bfc22"
    let thingTypeId = "1da44921-eacd-45ec-be97-d01a81d8b92c"
    creator.create(token: token, name: name, serialNumber: serialNumber, thingTypeId: thingTypeId)
      .subscribe { event in
        switch event {
        case .next:
          XCTAssert(false)
        case .error:
          testExpectation.fulfill()
        case .completed:
          XCTAssert(false)
        }
      }
      .addDisposableTo(disposeBag)
    
    waitForExpectations(timeout: 1, handler: nil)
  }
  
}
