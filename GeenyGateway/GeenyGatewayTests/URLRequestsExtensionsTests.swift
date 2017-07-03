//
//  URLRequestsExtensionsTests.swift
//  GatewayTests
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import XCTest
@testable import GeenyGateway

class URLRequestsExtensionsTests: XCTestCase {
  
  private struct Constants {
    static let urlString = "https://test.org"
    static let methodPost = "POST"
    static let contentTypeKey = "Content-Type"
    static let contentTypeJSON = "application/json; charset=utf-8"
    static let acceptKey = "Accept"
    static let acceptJSON = "application/json"
  }
  
  func testPost_allNils() {
    let request = URLRequest.geenyCreatePost(urlString: Constants.urlString, additionalHeader: nil, jsonBody: nil)
    performEssentialPostAsserts(on: request)
  }
  
  private func performEssentialPostAsserts(on request: URLRequest?, includingAcceptHeader: Bool = true) {
    XCTAssertNotNil(request)
    guard let request = request else {
      return
    }
    
    XCTAssertNotNil(request.url)
    XCTAssertEqual(request.url!.absoluteString, Constants.urlString)
    XCTAssertEqual(request.httpMethod, Constants.methodPost)
    
    XCTAssertNotNil(request.allHTTPHeaderFields)
    guard let headerFields = request.allHTTPHeaderFields else {
      return
    }
    
    XCTAssertEqual(headerFields[Constants.contentTypeKey], Constants.contentTypeJSON)
    if includingAcceptHeader  {
      XCTAssertEqual(headerFields[Constants.acceptKey], Constants.acceptJSON)
    }
  }
  
  func testPost_customHeadersNotOverriding() {
    let headers = [
      "testKey1": "testValue1",
      "testKey2": "testValue2"
    ]
    let request = URLRequest.geenyCreatePost(urlString: Constants.urlString, additionalHeader: headers, jsonBody: nil)
    performEssentialPostAsserts(on: request)
  
    if let headerFields = request?.allHTTPHeaderFields {
      XCTAssertEqual(headerFields["testKey1"], "testValue1")
      XCTAssertEqual(headerFields["testKey2"], "testValue2")
    }
  }
  
  func testPost_customHeadersOverriding() {
    let acceptXml = "application/xml"
    let headers = [
      Constants.acceptKey: acceptXml,
      "testKey2": "testValue2"
    ]
    let request = URLRequest.geenyCreatePost(urlString: Constants.urlString, additionalHeader: headers, jsonBody: nil)
    performEssentialPostAsserts(on: request, includingAcceptHeader: false)
    
    guard let headerFields = request?.allHTTPHeaderFields else {
      XCTAssert(false)
      return
    }
    XCTAssertEqual(headerFields[Constants.acceptKey], acceptXml)
    XCTAssertEqual(headerFields["testKey2"], "testValue2")
  }
  
  func testPost_customBody() {
    let body = [
      "testKey1": "testValue1",
      "testKey2": "testValue2"
    ]
    let request = URLRequest.geenyCreatePost(urlString: Constants.urlString, additionalHeader: nil, jsonBody: body)
    performEssentialPostAsserts(on: request)
    
    guard let bodyData = request?.httpBody,
      let object = try? JSONSerialization.jsonObject(with: bodyData, options: []),
      let json = object as? [String: String] else {
      XCTAssert(false)
      return
    }
    XCTAssertEqual(body, json)
  }
  
}
