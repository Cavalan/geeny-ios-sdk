//
//  RESTTokenManagerTests.swift
//  GatewayExample
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

class RESTTokenManagerTests: XCTestCase {
  
  private var manager: RESTTokenManager!
  private let disposeBag = DisposeBag()
  
  override func setUp() {
    super.setUp()
    
    manager = RESTTokenManager()
    manager.reset()
  }
  
  func testLogin_succeeds() {
    let tokenExpectation = expectation(description: "Expect succeeds and token stored")
    
    stub(condition: LoginCommons.postLoginCondition()) { request -> OHHTTPStubsResponse in
      let path = OHPathForFile(LoginCommons.response200Filename, TokenFetcherTests.self)!
      return fixture(filePath: path, status: 200, headers: nil)
    }
    
    XCTAssertFalse(manager.hasToken)
    manager.login(username: LoginCommons.validUsername, password: LoginCommons.validPassword)
      .subscribe { event in
        switch event {
        case .next(let token):
          XCTAssertFalse(token.isEmpty)
          XCTAssertTrue(self.manager.hasToken)
          tokenExpectation.fulfill()
        case .error:
          XCTAssert(false)
        case .completed:
          break
        }
      }
      .addDisposableTo(disposeBag)

    waitForExpectations(timeout: 0.1, handler: nil)
  }
  
  func testLogin_fails() {
    let tokenExpectation = expectation(description: "Expect error")

    stub(condition: LoginCommons.postLoginCondition()) { request -> OHHTTPStubsResponse in
      let path = OHPathForFile(LoginCommons.response400Filename, TokenFetcherTests.self)!
      return fixture(filePath: path, status: 400, headers: nil)
    }

    XCTAssertFalse(manager.hasToken)
    manager.login(username: LoginCommons.invalidUsername, password: LoginCommons.invalidPassword)
      .subscribe { event in
        switch event {
        case .next:
          XCTAssert(false)
        case .error:
          XCTAssertFalse(self.manager.hasToken)
          tokenExpectation.fulfill()
        case .completed:
          break
        }
      }
      .addDisposableTo(disposeBag)

    waitForExpectations(timeout: 0.1, handler: nil)
  }
  
  func testLogout_succeeds() {
    let tokenExpectation = expectation(description: "Expect token to be nil after log out")
    
    stub(condition: LoginCommons.postLoginCondition()) { request -> OHHTTPStubsResponse in
      let path = OHPathForFile(LoginCommons.response200Filename, TokenFetcherTests.self)!
      return fixture(filePath: path, status: 200, headers: nil)
    }

    // Log in first
    XCTAssertFalse(manager.hasToken)
    manager.login(username: LoginCommons.validUsername, password: LoginCommons.validPassword)
      .subscribe { event in
        switch event {
        case .next(let token):
          XCTAssertFalse(token.isEmpty)
          XCTAssertTrue(self.manager.hasToken)
          
          // And log out
          self.manager.logout()
          XCTAssertFalse(self.manager.hasToken)
          
          tokenExpectation.fulfill()
        case .error:
          XCTAssert(false)
        case .completed:
          break
        }
      }
      .addDisposableTo(disposeBag)
    
    waitForExpectations(timeout: 0.1, handler: nil)
  }
  
}
