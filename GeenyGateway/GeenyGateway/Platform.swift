//
//  Platform.swift
//  GeenyGateway
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this file,
//  You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit

// https://stackoverflow.com/a/30284266/284811
struct Platform {
  
  static var isSimulator: Bool {
    return TARGET_OS_SIMULATOR != 0
  }
  
}

