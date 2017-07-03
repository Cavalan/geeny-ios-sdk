//
//  ThingRegistrar.swift
//  GeenyGateway
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit
import CoreBluetooth
import RxSwift

public typealias RegisterResultBlock = (Result<Thing>)->Void
public typealias ThingBlock = (Thing?)->Void

class ThingRegistrar: NSObject {
  
  private let cache: RegistrationCache
  private let tokenManager: TokenManaging
  private let certificateStore: CertificateStore
  
  init(cache: RegistrationCache, tokenManager: TokenManaging, certificateStore: CertificateStore) {
    self.cache = cache
    self.tokenManager = tokenManager
    self.certificateStore = certificateStore
    super.init()
  }
  
  func registerWithSimpleFlow(userGivenName: String, thingInfo: ThingInfo) -> Observable<ThingInfo> {
    guard let geenyThingInfo = thingInfo.geenyThingInfo else {
      return Observable.error(GatewayError.thingIsNotGeenyNative)
    }
    
    let thingTypeId = geenyThingInfo.thingType
    let serialNumber = geenyThingInfo.serialNumber
    return createThingIfNecessary(userGivenName: userGivenName, thingInfo: thingInfo, thingTypeId: thingTypeId, serialNumber: serialNumber, attributes: nil)
  }
  
  func isRegistered(thingInfo: ThingInfo) -> Bool {
    return cache.thingInfo(forThingUUID: thingInfo.peripheralId) != nil
  }

  func registeredThings() -> [ThingInfo] {
    return cache.getRegisteredThings()
  }

  func updateThingInfo(_ thingInfo: ThingInfo){
    self.cache.set(thingInfo: thingInfo, forThingUUID: thingInfo.peripheralId)
    self.cache.persist()
  }

  // MARK: - Things
  
  /// Returns the generated Geeny Thing ID from API.
  private func createThingIfNecessary(userGivenName: String, thingInfo: ThingInfo, thingTypeId: String, serialNumber: String, attributes: [String: Any]?) -> Observable<ThingInfo> {
    if thingInfo.geenyId != nil {
      return Observable.just(thingInfo)
    } else {
      guard tokenManager.hasToken else {
        return Observable.error(APIError.noCredentials)
      }
      
      return tokenManager.refreshedToken()
        .flatMap{ token -> Observable<ThingInfo> in
          return self.createThing(token: token, userGivenName: userGivenName, thingInfo: thingInfo, thingTypeId: thingTypeId, serialNumber: serialNumber, attributes: attributes)
        }
    }
  }
  
  /// Returns the generated Thing ID from backend.
  private func createThing(token: String, userGivenName: String, thingInfo: ThingInfo, thingTypeId: String, serialNumber: String, attributes: [String: Any]?) -> Observable<ThingInfo> {
    let creator = ThingCreator()
    return creator.create(token: token, name: userGivenName, serialNumber: serialNumber, thingTypeId: thingTypeId)
      .flatMap{ response -> Observable<ThingInfo> in
        let thingId = response.thingId
        print("==== REGISTERED THING, ID:\n| \(thingId)")
        // Store certificates
        let addResult = self.addCertificate(response: response.certs, forThingId: thingId)
        if addResult {
          print("==== ADDED CERTIFICATE, ID:\n| \(thingId)")
          let updatedThingInfo = thingInfo.updatedWith(userGivenName: userGivenName, geenyId: thingId)
          self.cache.set(thingInfo: updatedThingInfo, forThingUUID: thingInfo.peripheralId)
          self.cache.persist()
          self.cache.printAllMappings()
          return Observable.just(updatedThingInfo)
        } else {
          return Observable.error(GatewayError.cannotAddCertificate)
        }
      }
  }

  func userGivenName(peripheralId: String) -> String? {
    return cache.thingInfo(forThingUUID: peripheralId)?.name
  }
  
  // MARK: - Certificate
  
  private func addCertificate(response: PostThingResponse.CertificateResponse, forThingId thingId: String) -> Bool {
    let privateKey = response.privateKey
    let encryptedPrivateKey = CertificateUtils.encryptPrivateKey(privateKey, withPassword: thingId)
    let info = CertificateInfo(caCertificate: response.caCertificate, clientCertificate: response.clientCertificate, encryptedKey: encryptedPrivateKey)
    let storeResult = certificateStore.store(info, for: thingId)
    assert(storeResult != nil)
    print("stored certs: \(String(describing: storeResult))")
    return (storeResult != nil)
  }
  
}
