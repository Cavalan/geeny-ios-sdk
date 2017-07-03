//
//  CertificateStore.swift
//  GeenyGateway
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit
import KeychainSwift

struct CertificateInfo {
  let caCertificate: String
  let clientCertificate: String
  let encryptedKey: String
}

/// This struct always stores *relative* paths to Documents folder.
struct CertificatePaths {
  let caCertificatePath: String
  let clientCertificatePath: String
  let encryptedKeyPath: String
}

class CertificateStore {
  
  private let keychain = KeychainSwift()
  // Intentionally let the folder name a bit cryptic. Relative to Documents folder.
  private static let certificatesRelativePath = "geenyc"
  
  func store(_ certificateInfo: CertificateInfo, for thingUUID: String) -> CertificatePaths? {
    // TODO delete old certificates if uuid exists.
    
    // Generate filenames
    let certificatesFolder = CertificateStore.certificatesRelativePath as NSString
    let caRelativePath = certificatesFolder.appendingPathComponent(UUID().uuidString)
    let clientRelativePath = certificatesFolder.appendingPathComponent(UUID().uuidString)
    let keyRelativePath = certificatesFolder.appendingPathComponent(UUID().uuidString)
    
    let documentsFolder = PathUtils.documentsFolderPath() as NSString
    let caAbsolutePath = documentsFolder.appendingPathComponent(caRelativePath)
    let clientAbsolutePath = documentsFolder.appendingPathComponent(clientRelativePath)
    let keyAbsolutePath = documentsFolder.appendingPathComponent(keyRelativePath)
    
    // Writing certs to disk
    do {
      let absoluteCertificatesFolder = documentsFolder.appendingPathComponent(certificatesFolder as String)
      if !FileManager.default.fileExists(atPath: absoluteCertificatesFolder) {
        try FileManager.default.createDirectory(atPath: absoluteCertificatesFolder, withIntermediateDirectories: true, attributes: nil)
      }
      try certificateInfo.caCertificate.write(toFile: caAbsolutePath, atomically: true, encoding: .utf8)
      try certificateInfo.clientCertificate.write(toFile: clientAbsolutePath, atomically: true, encoding: .utf8)
      try certificateInfo.encryptedKey.write(toFile: keyAbsolutePath, atomically: true, encoding: .utf8)
    } catch let e {
      print("[WARN] Could not write certificate: \(e)")
      return nil
    }
    
    // Storing file paths
    let accessLevel = KeychainSwiftAccessOptions.accessibleAfterFirstUnlock
    let caCertResult = keychain.set(caRelativePath, forKey: caCertPathKey(for: thingUUID), withAccess: accessLevel)
    let clientCertResult = keychain.set(clientRelativePath, forKey: clientCertPathKey(for: thingUUID), withAccess: accessLevel)
    let privateKeyResult = keychain.set(keyRelativePath, forKey: privateKeyPathKey(for: thingUUID), withAccess: accessLevel)
    
    if caCertResult && clientCertResult && privateKeyResult {
      return CertificatePaths(caCertificatePath: caRelativePath, clientCertificatePath: clientRelativePath, encryptedKeyPath: keyRelativePath)
    } else {
      print("[WARN] Could not store certificate paths to keychain.")
      return nil
    }
  }
  
  func certificatePaths(for thingUUID: String) -> CertificatePaths? {
    if let caCertPath = keychain.get(caCertPathKey(for: thingUUID)),
      let clientCertPath = keychain.get(clientCertPathKey(for: thingUUID)),
      let privateKeyPath = keychain.get(privateKeyPathKey(for: thingUUID)) {
      return CertificatePaths(caCertificatePath: caCertPath, clientCertificatePath: clientCertPath, encryptedKeyPath: privateKeyPath)
    }
    return nil
  }
  
  private func caCertPathKey(for uuid: String) -> String {
    return "caCert-"
  }
  
  private func clientCertPathKey(for uuid: String) -> String {
    return "clientCert-"
  }
  
  private func privateKeyPathKey(for uuid: String) -> String {
    return "privateKey-"
  }
  
}
