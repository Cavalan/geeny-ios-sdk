//
//  AlertUtils.swift
//  GeenyGateway
//
//  Created by Shuo Yang on 7/21/17.
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit
import GeenyGateway

class AlertUtils {
  
  static func presentAlert(in viewController: UIViewController, title: String?, message: String?, buttonLabel: String? = "OK") {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: buttonLabel, style: .default, handler: nil))
    DispatchQueue.main.async {
      viewController.present(alert, animated: true, completion: nil)
    }
  }
  
  static func presentTokenRevokedAlert(in viewController: UIViewController) {
    let title = "Please log in again"
    let message = "Your current login credentials has been revoked. Please log in again."
    presentAlert(in: viewController, title: title, message: message)
  }
  
  static func presentPleaseLoginAlert(in viewController: UIViewController) {
    let title = "Please Log In First"
    let message = "Subsequent functionalities require that you are logged in to Geeny Connect. Please go back to Nearby Things and log in there."
    presentAlert(in: viewController, title: title, message: message)
  }
  
  static func presentCannotRegisterAlert(in viewController: UIViewController, error: Error) {
    let title = "Registration Failed"
    let message: String
    switch error {
    case APIError.invalidThingTypeId:
      message = "Unknown Thing Type ID. Is this Thing Type already registered in the Geeny cloud? (Error: \(error))"
    default:
      message = "Could not register. (Error: \(error))"
    }
    presentAlert(in: viewController, title: title, message: message)
  }
  
  static func presentEnterNameAlert(in viewController: UIViewController, thingInfo: ThingInfo, registerAction: @escaping (String)->()) {
    let title = "Please Name Your Thing"
    let identifier: String
    if let oldName = thingInfo.name {
      identifier = oldName
    } else {
      identifier = thingInfo.peripheralId
    }
    let message = "Please give a name to the thing '\(identifier). This name will be used to identify the thing."
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addTextField { (textField) in
      textField.placeholder = thingInfo.name
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    let registerAction = UIAlertAction(title: "Register", style: .default) { (action) in
      if let name = alert.textFields?.first?.text {
        registerAction(name)
      } else {
        registerAction(identifier)
      }
    }
    alert.addAction(registerAction)
    alert.addAction(cancelAction)
    viewController.present(alert, animated: true, completion: nil)
  }

}
