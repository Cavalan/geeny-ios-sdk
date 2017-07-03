//
//  TokenFetcherTests.swift
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

class TokenRefresherTests: XCTestCase {
  
  private var refresher: TokenRefresher!
  private let disposeBag = DisposeBag()
  
  override func setUp() {
    super.setUp()
    refresher = TokenRefresher()
  }
  
  func postRefreshCondition() -> OHHTTPStubsTestBlock {
    return isMethodPOST() && isHost(Endpoint.connectHost) && isPath(TokenRefresher.Constants.path)
  }
  
  func testRefreshingToken_succeeds() {
    let tokenExpectation = expectation(description: "Should return a non empty token")
    
    stub(condition: postRefreshCondition()) { request -> OHHTTPStubsResponse in
      let path = OHPathForFile("post-refresh-200.json", TokenFetcherTests.self)!
      return fixture(filePath: path, status: 200, headers: nil)
    }

    let token = "eyJhbGciOi_expiredToken"
    refresher.refresh(oldToken: token)
      .subscribe { event in
        switch event {
          case .next(let token):
            XCTAssertFalse(token.isEmpty)
          case .error:
            XCTAssert(false)
          case .completed:
            tokenExpectation.fulfill()
        }
      }
      .addDisposableTo(disposeBag)
    
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  func testRefreshingToken_invalidOldToken() {
    let tokenExpectation = expectation(description: "Should return an error")

    stub(condition: postRefreshCondition()) { request -> OHHTTPStubsResponse in
      let path = OHPathForFile("post-refresh-400.json", TokenFetcherTests.self)!
      return fixture(filePath: path, status: 400, headers: nil)
    }

    let token = "eyJhbGciOi_invalidToken"
    refresher.refresh(oldToken: token)
      .subscribe { event in
        switch event {
          case .error:
            XCTAssert(true)
          default:
            XCTAssert(false)
        }
        tokenExpectation.fulfill()
      }
      .addDisposableTo(disposeBag)

    waitForExpectations(timeout: 1, handler: nil)
  }

}
