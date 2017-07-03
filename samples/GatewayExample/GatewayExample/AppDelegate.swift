//
//  AppDelegate.swift
//  GatewayExample
//
//  Created by Shuo Yang on 21.04.17.
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit
import GeenyGateway

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // Initialize Geeny Gateway
    Gateway.shared.setUp()
    return true
  }
  
}

