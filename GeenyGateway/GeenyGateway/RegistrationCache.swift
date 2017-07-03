//
//  RegistrationCache.swift
//  GeenyGateway
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit

/// JSON-based storage.
class RegistrationCache: Codable {

  private let schemaVersion = 1

  // Key: Characteristic ID
  // Value: Message Type ID (from server)
  private var messageTypes = [String: String]()
  
  // Key: Thing Type Name
  // Value: Thing Type ID (from server)
  private var thingTypes = [String: String]()

  // Key: Thing UUID
  // Value: ThingInfo instance
  private var thingsInfo = [String: ThingInfo]()

  private struct Constants {
    static let gatewayFolder = "geenyGateway"
    static let jsonFilename = "registrationCache.json"
  }

  private init() {}

  static let shared: RegistrationCache = {
    let path = jsonFilePath()
    if let data = NSData(contentsOfFile: path) {
      do {
        let registrationCache = try JSONDecoder().decode(RegistrationCache.self, from: data as Data)
        return registrationCache
      } catch let e {
        print("[WARN]: Couldn't decode json cache trying to recover")
        if let json = JSONSerialization.geenySimpleJSONObject(from: data as Data) {
          // check for schemaVersion and try to map old cache to new schema
          print(json)
        }
      }
    }
    return RegistrationCache()
  }()

  private static func jsonFilePath() -> String {
    let components = [
      Constants.gatewayFolder,
      Constants.jsonFilename
    ]
    return PathUtils.pathInDocumentsFolder(components: components)
  }
  
  func persist() {
    let path = RegistrationCache.jsonFilePath()

    do {
      let directory = (path as NSString).deletingLastPathComponent
      if !FileManager.default.fileExists(atPath: directory) {
        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
      }
      let url = URL(fileURLWithPath: path)
      let data = try JSONEncoder().encode(self)
      try data.write(to: url)
    } catch let e {
      print("[WARN] Cannot write data to: \(path). Error: \(e)")
    }
  }
  
  func deleteEverything() {
    messageTypes.removeAll()
    thingTypes.removeAll()
    thingsInfo.removeAll()
  }
  
  func printAllMappings() {
    print()
    print("==== BEGIN CACHE DUMP ====")
    print("Message Types:\n\(messageTypes)")
    print("Thing Types:\n\(thingTypes)")
    print("Thing Info:\n\(thingsInfo)")
    print("==== END CACHE DUMP ====")
    print()
  }
  
  // MARK: - Message Types
  
  func messageTypeId(forCharacteristicId id: String) -> String? {
    return messageTypes[id]
  }
  
  func set(messageTypeId: String, forCharacteristicId characteristicId: String) {
    messageTypes[characteristicId] = messageTypeId
  }
  
  // MARK: - Thing Types
  
  func thingTypeId(forName name: String) -> String? {
    return thingTypes[name]
  }
  
  func set(thingTypeId: String, forName name: String) {
    thingTypes[name] = thingTypeId
  }

  // MARK: - ThingInfo

  func thingInfo(forThingUUID uuid: String) -> ThingInfo? {
    return thingsInfo[uuid]
  }

  func set(thingInfo: ThingInfo, forThingUUID uuid: String) {
    thingsInfo[uuid] = thingInfo
  }

  func getRegisteredThings() -> [ThingInfo] {
    return Array(thingsInfo.values)
  }
}
