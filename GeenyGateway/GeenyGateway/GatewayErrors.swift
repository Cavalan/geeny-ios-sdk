//
//  GatewayErrors.swift
//  GeenyGateway
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit

/// Possible errors during the scanning for Things.
public enum ScanError: Error {
  /// Scan could not start before time runs out.
  case timeout
  /// Bluetooth is turned off therefore no scan is possible.
  case poweredOff
  /// Bluetooth is not supported, for example when running in Simulator.
  case unsupported
  /// CBCentralManager is not ready yet. Please try again later.
  case invalidStatePleaseTryLater
}

/// Errors during API calls to the backend.
public enum APIError: Error {
  /// Username and password are not provided.
  case noCredentials
  /// Invalid username and/or password.
  case invalidCredentials
  /// Invalid HTTP request
  case invalidRequest
  /// The JSON response received has invalid schema or content.
  case invalidJSON
  /// The given ThingTypeId during the registration process
  /// is unknown to the Geeny Cloud. Currently we require the ThingType
  /// to be pre-registered.
  case invalidThingTypeId
  /// The user is not authorized.
  case unauthorized
}

/// General errors for the Gateway SDK
public enum GatewayError: Error {
  /// Gateway SDK is performing an ongoing operation and cannot handle
  /// a second one in parallel. Please make sure the ongoing operation
  /// is done then try again.
  case busyPleaseRetryLater
  /// Due to some unexpected issues the operation could not be completed.
  /// For example, Bluetooth connectivity issues. Please try again.
  case pleaseRetryLater
  /// The given UUID string is not a valid UUID.
  case invalidUUIDString
  /// User has cancelled the operation.
  case cancelled
  /// The Thing is not Geeny-native thus not yet supported.
  case thingIsNotGeenyNative
  /// Could not store the certificates.
  case cannotAddCertificate
  /// Associated peripheral of the Thing can't be found
  case illegalInternalState
  /// The characteristic can't be subscribed to
  case characteristicCantBeSubscribedTo
}
