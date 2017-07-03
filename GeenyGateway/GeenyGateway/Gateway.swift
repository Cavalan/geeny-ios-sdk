//
//  Gateway.swift
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

public typealias ThingInfoBlock = (Result<ThingInfo>)->()

/// The entrance point of the Geeny Gateway SDK.
public class Gateway: NSObject {

  /// Returns a shared singleton Gateway object.
  public static let shared = Gateway(tokenManager: RESTTokenManager(), centralManager: CBCentralManager())

  private let tokenManager: TokenManaging
  private let bleCommunicator: BLECommunicator
  private let thingRegistrar: ThingRegistrar
  private let thingProvider: ThingProvider

  private let disposeBag = DisposeBag()

  init(tokenManager: TokenManaging, centralManager: BLECentralManaging) {
    self.tokenManager = tokenManager
    bleCommunicator = BLECommunicator(centralManager: centralManager)
    let certificateStore = CertificateStore()
    let cache = RegistrationCache.shared
    thingRegistrar = ThingRegistrar(cache: cache, tokenManager: tokenManager, certificateStore: certificateStore)
    thingProvider = ThingProvider(bleCommunicator: bleCommunicator, registrationCache: cache, certificateStore: certificateStore)
    super.init()
  }

  // MARK: - Initialization

  /// Initialize the Gateway SDK with the given configuration options (coming later).
  public func setUp() {}

  // MARK: - Authentication

  /// Return whether the user is logged in into Geeny. Technically it returns
  /// whether the access token is stored.
  public var isLoggedIn: Bool {
    return tokenManager.hasToken
  }

  /// Perform login into Geeny with the given username and password. When finished,
  /// the completion block will be called with a boolean true for success,
  /// or an error describing the cause.
  ///
  /// - Parameters:
  ///   - username: The username to log in.
  ///   - password: The password to log in.
  ///   - completion: Completion block for boolean true or error.
  public func login(username: String, password: String, completion: @escaping LoginResultBlock) {
    tokenManager.login(username: username, password: password)
      .subscribe { event in
        switch event {
        case .next:
          completion(Result.success(true))
        case .error(let e):
          completion(Result.error(e))
        case .completed:
          break
        }
      }.addDisposableTo(disposeBag)
  }

  /// Manually log out. Technically it deletes the locally stored tokens.
  public func logout() {
    tokenManager.logout()
  }

  // MARK: - Discovery

  /// Scan for nearby Bluetooth LE things for the given time period. When the timer
  /// runs out, the completion block will be called with either the metadata of
  /// the detected things (`ThingInfo`), or a `ScanError` object.
  ///
  /// This method handles the `CBCentralManager` initialization automatically.
  ///
  /// - Parameters:
  ///   - timeout: Specifies how long the scan should last. Default is 2 seconds.
  ///   - onlyGeenyNative: Allows to filter the list of found things to include only Geeny native ones. Default is false.
  ///   - omitRegisteredThings: Allows to omit the registered things from the list of scanned things. Default is false.
  ///   - completion: Completion block for the `[ThingInfo]` result or error.
  public func scanForThings(timeout: TimeInterval = 2.0, onlyGeenyNative: Bool = false, omitRegisteredThings: Bool = false, completion: @escaping ScanResultBlock) {
    bleCommunicator.scanForThings(timeout: timeout) {  [weak self] result in
      guard let `self` = self else { return }

      switch result {
      case .success(let thingInfo):
        var filteredThingInfo = thingInfo
        if onlyGeenyNative {
          filteredThingInfo = filteredThingInfo.filter{ $0.isGeenyNative }
        }
        if omitRegisteredThings {
          filteredThingInfo = filteredThingInfo.filter{ !self.thingRegistrar.isRegistered(thingInfo: $0) }
        }
        completion(Result.success(filteredThingInfo))
      default: completion(result)
      }
    }
  }

  /// Connect to peripheral and discover characteristics for a *ThingInfo* including Geeny-specific
  /// information as `GeenyThingInfo`.
  /// The process can be cancelled via the Progress return value.
  /// The completion block is always called, with either an updated *ThingInfo* instance or
  /// an error.
  ///
  /// This method handles the `CBCentralManager` initialization automatically.
  ///
  /// - Parameters:
  ///   - thingInfo: A `ThingInfo` instance.
  ///   - completion: Completion block with an updated `ThingInfo` result or error.
  public func connectAndDiscoverCharacteristics(for thingInfo: ThingInfo, completion: @escaping ThingInfoBlock) -> Progress {
    return bleCommunicator.connectToPeripheral(withIdentifier: thingInfo.peripheralId) { result in
      switch result {
      case .success(let peripheral):
        self.bleCommunicator.detectGATT(in: peripheral) { result in
          switch result {
          case .success(let characteristics, let geenyThingInfo):
            let updatedThingInfo = thingInfo.updatedWith(geenyThingInfo: geenyThingInfo, characteristics: characteristics)
            completion(Result.success(updatedThingInfo))
          case .error(let e):
            completion(Result.error(e))
          }
        }
      case .error(let e):
        print("[WARN] Error detecting GATT: \(e)")
        completion(Result.error(e))
      }
    }
  }

  // MARK: - Registering Things

  /// Register the thing given its `ThingInfo` representation on the Geeny Cloud.
  /// Currently only the "simple flow" is used: the Thing must be Geeny-native,
  /// and its ThingType must be pre-registered on the Geeny Cloud.
  ///
  /// After successful registration, the certificates are also obtained,
  /// which will be used for further MQTT communications.
  ///
  /// - Parameters:
  ///   - userGivenName: The name given by the user to identify the thing.
  ///   - thingInfo: Represents a Thing.
  ///   - completion: Completion block with a `Thing` object result or error.
  public func registerThing(userGivenName: String, thingInfo: ThingInfo, completion: @escaping RegisterResultBlock) {
    thingRegistrar.registerWithSimpleFlow(userGivenName: userGivenName, thingInfo: thingInfo)
      .subscribe { (event) in
        switch event {
        case .next(let thingInfo):
          print("==== THING ID: \(thingInfo.geenyId ?? "") ====")
          let thing = self.thingProvider.thing(with: thingInfo)
          completion(Result.success(thing))
        case .completed:
          break
        case .error(let e):
          print("REG ERROR! \(e)")
          completion(Result.error(e))
        }
      }
      .addDisposableTo(self.disposeBag)
  }

  /// Update a Thing given its `ThingInfo`.
  ///
  /// It updates the thingInfo in the corresponding thing,
  /// and persits the changes in the thingRegistrar.
  ///
  /// - Parameters:
  ///   - thingInfo: Containing the updated information about a thing.
  public func updateThing(with thingInfo: ThingInfo) {
    if self.isThingRegistered(thingInfo: thingInfo) {
      thingRegistrar.updateThingInfo(thingInfo)
      let thing = thingProvider.thing(with: thingInfo)
      thing.info = thingInfo
    }
  }

  /// Retrieve all registered Things as an array of `ThingInfo` instances.
  ///
  /// - Parameters:
  ///   - completion: Completion block for the `[ThingInfo]` result or error.
  public func registeredThings(completion: ScanResultBlock) {
    completion(Result.success(thingRegistrar.registeredThings()))
  }

  /// Retrieve a registered thing given its `ThingInfo` representation
  ///
  /// - Parameters:
  ///   - thingInfo: Represents a Thing.
  ///   - completion: Completion block with a `Thing` object result or error.
  public func registeredThing(thingInfo: ThingInfo, completion: @escaping ThingBlock) {
    if isThingRegistered(thingInfo: thingInfo) {
      let thing = thingProvider.thing(with: thingInfo)
      completion(thing)
    } else {
      completion(nil)
    }
  }

  /// Queries whether the thing, represented by the given `ThingInfo`,
  /// is registered on the Geeny Cloud. This only checks the locally cached
  /// state.
  ///
  /// - Parameters:
  ///   - thingInfo: Represents a Thing.
  public func isThingRegistered(thingInfo: ThingInfo) -> Bool {
    return thingRegistrar.isRegistered(thingInfo: thingInfo)
  }

  /// Queries whether the thing, represented by the given `ThingInfo`,
  /// is connected.
  ///
  /// - Parameters:
  ///   - thingInfo: Represents a Thing.
  public func isThingConnected(thingInfo: ThingInfo) -> Bool {
    return bleCommunicator.connectedPeripheral(withIdentifier: thingInfo.peripheralId) != nil
  }
  
  // MARK: - Debugging

  /// Resets the internal cache of Geeny Gateway SDK. This method must only be used for
  /// debugging purposes.
  public func debug_reset() {
    tokenManager.reset()
  }

}
