//
//  ThingCreator.swift
//  GeenyGateway
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

struct PostThingResponse: Codable {
  let thingId: String
  let thingName: String
  let serialNumber: String
  let thingType: String
  let certs: CertificateResponse
  let created: Date
  
  private enum CodingKeys: String, CodingKey {
    case thingId = "id"
    case thingName = "name"
    case serialNumber = "serial_number"
    case thingType = "thing_type"
    case certs
    case created
  }
  
  struct CertificateResponse: Codable {
    let caCertificate: String
    let clientCertificate: String
    let privateKey: String
    
    private enum CodingKeys: String, CodingKey {
      case caCertificate = "ca"
      case clientCertificate = "cert"
      case privateKey = "key"
    }
  }
}

class ThingCreator: NSObject {
  struct Constants {
    static let path = "/things/api/v1/things"
    static let urlString = Endpoint.thingManagerURLString(path: path)
  }
  
  func create(token: String, name: String, serialNumber: String, thingTypeId: String) -> Observable<PostThingResponse> {
    let body = [
      "name": name,
      "serial_number": serialNumber,
      "thing_type": thingTypeId
    ]
    guard let request = URLRequest.geenyCreatePost(urlString: Constants.urlString, token: token, jsonBody: body) else {
      print("[WARN] Cannot create thingCreation request")
      return Observable.error(APIError.invalidRequest)
    }
    
    return URLSession.geeny.rx.response(request: request)
      .catchError({ (error) -> Observable<(response: HTTPURLResponse, data: Data)> in
        print("error: \(error)")
        return Observable.never()
      })
      .flatMap({ (result: (HTTPURLResponse, Data)) -> Observable<PostThingResponse> in
        let (response, data) = result
        return self.transformResponse(httpResponse: response, data: data)
      })
  }
  
  private func transformResponse(httpResponse: HTTPURLResponse, data: Data) -> Observable<PostThingResponse> {
    switch httpResponse.statusCode {
      case 201:
        do {
          let decoded = try JSONDecoder.forGeenyResponses.decode(PostThingResponse.self, from: data)
          return Observable.just(decoded)
        } catch let e {
          print("[WARN] Couldn't parse PostThingResponse: \(e)")
          return Observable.error(APIError.invalidJSON)
        }
      case 400:
        return Observable.error(APIError.invalidThingTypeId)
      case 401:
        return Observable.error(APIError.unauthorized)
      default:
        return Observable.error(APIError.invalidRequest)
    }
  }
  
}
