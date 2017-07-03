//
//  LoginViewController.swift
//  BLEServiceBrowser
//
//  Created by Shuo Yang on 4/26/17.
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit
import GeenyGateway
import MBProgressHUD

class LoginViewController: UIViewController {
  
  @IBOutlet private weak var loginBarButtonItem: UIBarButtonItem!
  @IBOutlet private weak var usernameTextField: UITextField!
  @IBOutlet private weak var passwordTextField: UITextField!

  override func viewDidLoad() {
    super.viewDidLoad()
    passwordTextField.isSecureTextEntry = true
  }
  
  @IBAction func cancelButtonDidTap(_ sender: UIBarButtonItem) {
    dismiss(animated: true, completion: nil)
  }
  
  @IBAction func loginButtonDidTap(_ sender: UIBarButtonItem) {
    guard let username = usernameTextField.text,
      let password = passwordTextField.text else {
        print("[WARN] Username / pw not entered")
        return
    }
    
    Gateway.shared.login(username: username, password: password) { result in
      switch result {
      case .success:
        DispatchQueue.main.async {
          let hud = self.presentSucessHUD()
          hud.hide(animated: true, afterDelay: 1)
          hud.completionBlock = {
            self.dismiss(animated: true, completion: nil)
          }
        }
      case .error(let e):
        DispatchQueue.main.async {
          self.presentAlert(error: e)
        }
      }
    }
  }
  
  private func presentSucessHUD() -> MBProgressHUD {
    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
    hud.mode = .customView
    let image = UIImage(named: "checkmark")!.withRenderingMode(.alwaysTemplate)
    hud.customView = UIImageView(image: image)
    hud.label.text = "Success"
    return hud
  }
  
  private func presentAlert(error: Error) {
    print("Error fetching token: \(error)")
    let alert = UIAlertController(title: "Error Logging In", message: "Wrong credentials? Please try again. (Error: \(error))", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    present(alert, animated: true, completion: nil)
  }
  
  @IBAction func resetButtonDidTap(_ sender: Any) {
    Gateway.shared.debug_reset()
  }
  
}
