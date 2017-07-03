//
//  NearbyThingsViewController.swift
//  GatewayExample
//
//  Created by Shuo Yang on 21.04.17.
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit
import GeenyGateway
import MBProgressHUD

class NearbyThingsViewController: UIViewController {
  private struct Constants {
    static let seguePresentLogin = "PresentLoginModally"
    static let seguePushThingInfo = "PushThingInfo"
    static let subtitleCell = "SubtitleCell"
  }
  private enum Section: Int {
    case registeredThings = 0
    case scannedThings
    case count
  }
  
  private var sections = (registeredThings:[ThingInfo](),
                          scannedThings:[ThingInfo]())
  private var currentGATTDetectionProgress: Progress?
  private var promptedUserForLogin = false

  @IBOutlet private weak var tableView: UITableView!
  @IBOutlet private weak var scanBarButtonItem: UIBarButtonItem!
  @IBOutlet private weak var loginBarButtonItem: UIBarButtonItem!
  
  private var isRequestingRegisteredThings = false {
    didSet {
      UIApplication.shared.isNetworkActivityIndicatorVisible = isScanningForThings && !isRequestingRegisteredThings
      scanBarButtonItem.isEnabled = !isScanningForThings && !isRequestingRegisteredThings
    }
  }
  private var isScanningForThings = false {
    didSet {
      UIApplication.shared.isNetworkActivityIndicatorVisible = isScanningForThings && !isRequestingRegisteredThings
      scanBarButtonItem.isEnabled = !isScanningForThings && !isRequestingRegisteredThings
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if !Gateway.shared.isLoggedIn && !promptedUserForLogin {
      performSegue(withIdentifier: Constants.seguePresentLogin, sender: nil)
    }
    self.loginBarButtonItem.title = Gateway.shared.isLoggedIn ? "Logout" : "Login"
    if sections.scannedThings.count == 0 {
      startScanning()
    } else {
      tableView.reloadData()
    }
    loadRegisteredThings()
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == Constants.seguePushThingInfo {
      handleThingInfoSegue(segue)
    } else if segue.identifier == Constants.seguePresentLogin {
      promptedUserForLogin = true
    }
  }

  override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
    let loginButtonPressed = identifier == Constants.seguePresentLogin
    if loginButtonPressed && Gateway.shared.isLoggedIn {
      Gateway.shared.logout()

      let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
      hud.label.text = "Logging out"
      hud.hide(animated: true, afterDelay: 1)
      self.loginBarButtonItem.title = "Login"
      return false
    }
    return true
  }

  private func handleThingInfoSegue(_ segue: UIStoryboardSegue) {
    guard let thingInfoViewController = segue.destination as? ThingInfoViewController,
      let indexPath = tableView.indexPathForSelectedRow else {
        return
    }

    var section: [ThingInfo]!
    switch indexPath.section {
    case Section.registeredThings.rawValue: section = sections.registeredThings
    case Section.scannedThings.rawValue: section = sections.scannedThings
    default: break
    }
    let thingInfo = section[indexPath.row]
    thingInfoViewController.thingInfo = thingInfo
  }

  private func loadRegisteredThings() {

    if !isRequestingRegisteredThings {
      isRequestingRegisteredThings = true
      Gateway.shared.registeredThings{  [weak self] result in
        guard let `self` = self else { return }

        self.isRequestingRegisteredThings = false
        switch result {
        case .success(let scanResults):
          self.sections.registeredThings = scanResults
          self.reload(section: .registeredThings)
        case .error(let error):
          self.handleScanError(error)
        }
      }
    }
  }

  private func startScanning() {

    if !isScanningForThings {
      isScanningForThings = true
      self.reload(section: .scannedThings)

      Gateway.shared.scanForThings(timeout: 2.0, onlyGeenyNative: false, omitRegisteredThings: true) { [weak self] result in
        guard let `self` = self else { return }
        
        self.isScanningForThings = false
        switch result {
        case .success(let scanResults):
          self.sections.scannedThings = scanResults.sorted{ $0.isGeenyNative || !$1.isGeenyNative }
        case .error(let error):
          self.handleScanError(error)
        }
        self.reload(section: .scannedThings)
      }
    }
  }

  private func reload(section: Section) {
    self.tableView.reloadSections(IndexSet(integer: section.rawValue), with: .automatic)
  }

  @IBAction func scanButtonDidTap(_ sender: UIBarButtonItem) {
    startScanning()
    loadRegisteredThings()
  }

  private func handleScanError(_ error: Error) {
    if let text = messageForScanError(error) {
      AlertUtils.presentAlert(in: self, title: text, message: nil)
    }
  }
  
  private func messageForScanError(_ error: Error) -> String? {
    let text: String?
    switch error {
    case GatewayError.cancelled:
      text = nil
    case ScanError.poweredOff:
      text = "Bluetooth is currently turned off. Please turn it on and try again."
    case ScanError.unsupported:
      text = "Bluetooth is not supported on this device. Notice that the Simulator does not support Bluetooth."
    case ScanError.timeout:
      text = "Could not initialize Bluetooth. Please try again later."
    default:
      text = nil
    }
    return text
  }
}

extension NearbyThingsViewController: UITableViewDataSource, UITableViewDelegate {
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return Section.count.rawValue
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch section {
    case Section.registeredThings.rawValue: return sections.registeredThings.count
    case Section.scannedThings.rawValue: return sections.scannedThings.count == 0 && isScanningForThings ? 1 : sections.scannedThings.count
    default: return 0
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    // Loading cell
    if isScanningForThings && indexPath.section == Section.scannedThings.rawValue && sections.scannedThings.count == 0 {
      let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)
      cell.textLabel?.text = "Scanning …"
      return cell
    }

    // Thing cells
    let cell = tableView.dequeueReusableCell(withIdentifier: Constants.subtitleCell, for: indexPath) as! ThingTableViewCell

    var section: [ThingInfo]!
    switch indexPath.section {
    case Section.registeredThings.rawValue: section = sections.registeredThings
    case Section.scannedThings.rawValue: section = sections.scannedThings
    default: break
    }
    let thingInfo = section[indexPath.row]
    let thingName = thingInfo.name
    let userGivenName = thingInfo.userGivenName
    let uuid = thingInfo.peripheralId
    let isGeenyNative = thingInfo.isGeenyNative
    let isConnected = Gateway.shared.isThingConnected(thingInfo: thingInfo)

    let viewModel = ThingCellViewModel(thingName: thingName, userGivenName: userGivenName, uuid: uuid, isConnected: isConnected, isGeenyNative: isGeenyNative)
    cell.viewModel = viewModel
    return cell
  }
  
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    switch section {
    case Section.registeredThings.rawValue: return "Registered Things (\(sections.registeredThings.count))"
    case Section.scannedThings.rawValue: return "Nearby Things (\(sections.scannedThings.count))"
    default: return ""
    }
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 60.0
  }
  
  @objc private func progressHudDidCancel() {
    currentGATTDetectionProgress?.cancel()
  }
}

