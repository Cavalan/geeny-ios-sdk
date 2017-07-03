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

class TokenFetcherTests: XCTestCase {

  private var fetcher: TokenFetcher!
  private let disposeBag = DisposeBag()

  override func setUp() {
    super.setUp()
    fetcher = TokenFetcher()
  }

  func testFetchingToken_succeeds() {
    let tokenExpectation = expectation(description: "Should return a non empty token")

    stub(condition: LoginCommons.postLoginCondition()) { request -> OHHTTPStubsResponse in
      let path = OHPathForFile(LoginCommons.response200Filename, TokenFetcherTests.self)!
      return fixture(filePath: path, status: 200, headers: nil)
    }

    fetcher.fetchToken(username: LoginCommons.validUsername, password: LoginCommons.validPassword)
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

  func testFetchingToken_invalidCredentials() {
    let tokenExpectation = expectation(description: "Should return an error")

    stub(condition: LoginCommons.postLoginCondition()) { request -> OHHTTPStubsResponse in
      let path = OHPathForFile(LoginCommons.response400Filename, TokenFetcherTests.self)!
      return fixture(filePath: path, status: 400, headers: nil)
    }

    fetcher.fetchToken(username: LoginCommons.invalidUsername, password: LoginCommons.invalidPassword)
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

  func testFetchingToken_emptyCredentials() {
    let tokenExpectation = expectation(description: "Should return an error")

    stub(condition: LoginCommons.postLoginCondition()) { request -> OHHTTPStubsResponse in
      let path = OHPathForFile(LoginCommons.response400Filename, TokenFetcherTests.self)!
      return fixture(filePath: path, status: 400, headers: nil)
    }

    let username = ""
    let password = ""
    fetcher.fetchToken(username: username, password: password)
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
