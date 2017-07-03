//
//  ThingInfoViewController.swift
//  GeenyGateway
//
//  Created by Shuo Yang on 5/11/17.
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit
import GeenyGateway
import MBProgressHUD

class ThingInfoViewController: UIViewController {

  var thingInfo: ThingInfo!

  private struct Constants {
    static let seguePushCharacteristics = "PushCharacteristics"
  }
  let publishCharacteristicInfo = CharacteristicInfo(uuid: Config.publishCharacteristicInfo.uuid, description: "", topic: Config.publishCharacteristicInfo.topic, properties: .notify)
  let subscribeCharacteristicInfo = CharacteristicInfo(uuid: Config.subscribeCharacteristicInfo.uuid, description: "", topic: Config.subscribeCharacteristicInfo.topic, properties: .write)
  private var detectionProgress: Progress?
  private var thing: Thing?
  private lazy var dateFormatter: DateFormatter =  {
    let dateFormatter = DateFormatter()
    dateFormatter.timeStyle = DateFormatter.Style.medium
    return dateFormatter
  }()

  // Outlets
  @IBOutlet weak var loadingView: UIView!

  @IBOutlet weak var thingNameLabel: UILabel!
  @IBOutlet weak var peripheralIdLabel: UILabel!

  @IBOutlet weak var geenyCompatibleHeaderLabel: UILabel!
  @IBOutlet weak var serialNumberLabel: UILabel!
  @IBOutlet weak var thingTypeLabel: UILabel!
  @IBOutlet weak var geenyCompatibleThingView: UIView!
  @IBOutlet weak var genericThingView: UIView!
  @IBOutlet weak var geenyInfoView: UIView!
  @IBOutlet weak var characteristicsValuesTextView: UITextView!

  @IBOutlet weak var registerButtonReducedVerticalSpaceConstraint: NSLayoutConstraint!
  @IBOutlet weak var registerButton: UIButton!
  @IBOutlet weak var autoPublishSwitch: UISwitch!

  override func viewDidLoad() {
    super.viewDidLoad()

    assert(thingInfo != nil)

    loadingView.alpha = 1
    startDetecting()
    characteristicsValuesTextView.font = UIFont(name: "Courier", size: 15)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    // If back button tapped and detection is not yet complete
    // (see also https://stackoverflow.com/a/3445994)
    if let navigationController = navigationController,
      !navigationController.viewControllers.contains(self),
      let detectionProgress = detectionProgress,
      !detectionProgress.isFinished {
      detectionProgress.cancel()
      self.detectionProgress = nil
    }
  }

  @IBAction func autoPublishSwitchChanged(_ sender: UISwitch) {
    let updatedThingInfo = thingInfo.updatedWith(autoPublish: sender.isOn)
    Gateway.shared.updateThing(with: updatedThingInfo)
  }

  private func startDetecting() {
    detectionProgress = Gateway.shared.connectAndDiscoverCharacteristics(for: thingInfo) { result in

      self.detectionProgress = nil
      switch result {
      case .success(let thingInfo):
        self.thingInfo = thingInfo
        self.updateRegistration(thingInfo: thingInfo)
        self.displayThingInfo(thingInfo)
      case .error(let error):
        switch error {
        case GatewayError.cancelled:
          print("[INFO] Cancelled")
        default:
          print("[WARN] Error: \(error)")
          AlertUtils.presentAlert(in: self, title: "Error", message: error.localizedDescription)
        }
      }
    }
  }

  private func displayThingInfo(_ thingInfo: ThingInfo) {
    print(thingInfo.prettyPrintString())

    // hide loading overlay
    UIView.animate(withDuration: 0.3) {
      self.loadingView.alpha = 0
    }

    updateThingName(thingInfo: thingInfo)
    peripheralIdLabel.text = thingInfo.peripheralId

    if let geenyInfo = thingInfo.geenyThingInfo {
      geenyCompatibleThingView.isHidden = false
      genericThingView.isHidden = true
      registerButtonReducedVerticalSpaceConstraint.priority = UILayoutPriority(UILayoutPriority.defaultHigh.rawValue - 1)
      geenyCompatibleHeaderLabel.text = "Geeny-Native Thing, Protocol v\(geenyInfo.protocolVersion)"
      serialNumberLabel.text = geenyInfo.serialNumber
      thingTypeLabel.text = geenyInfo.thingType
    } else {
      geenyCompatibleThingView.isHidden = true
      genericThingView.isHidden = false
      geenyInfoView.isHidden = true
      registerButtonReducedVerticalSpaceConstraint.priority = UILayoutPriority(UILayoutPriority.defaultHigh.rawValue + 1)
    }
  }


  private func updateThingName(thingInfo: ThingInfo) {
    let userGivenName = thingInfo.userGivenName
    thingNameLabel.text = DisplayName.fullNameFrom(thingName: thingInfo.name, userGivenName: userGivenName, separator: "\n")
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    if let characteristicsViewController = segue.destination as? CharacteristicsViewController, let thingInfo = thingInfo {
      characteristicsViewController.thingInfo = thingInfo
    }
  }

  private func updateRegistration(thingInfo: ThingInfo) {
    if let _ = thingInfo.geenyThingInfo {
      registerButton.isEnabled = true
      autoPublishSwitch.isEnabled = true
      // TODO: remove check
      if Gateway.shared.isThingRegistered(thingInfo: thingInfo) {
        Gateway.shared.registeredThing(thingInfo: thingInfo) { thing in
          self.thing = thing
          self.publishData()
        }
        registerButton.setTitle("Unregister", for: .normal)
        registerButton.tintColor = UIColor.gray
        autoPublishSwitch.isOn = thingInfo.autoPublish

      } else {
        registerButton.setTitle("Register", for: .normal)
        registerButton.tintColor = UIColor.geenyGreen()
      }
    } else {
      // Non-geeny thing
      registerButton.isEnabled = false
      registerButton.setTitle("Not Supported", for: .normal)
      registerButton.tintColor = UIColor.lightGray
      autoPublishSwitch.isEnabled = false
      autoPublishSwitch.isOn = false
    }
  }

  private func publishData() {
    guard let thing = thing else { return }

    thing.readAndPublish(publishCharacteristicInfo) { [weak self] result -> Data? in
      guard let `self` = self else { return nil }
      switch result {
      case .success(let data):
        // Data is received from a Thing and published to the Geeny cloud.
        // At this point you can intercept the data to read it and optionally apply some filtering or transformation.
        // If you want to send the data as it is just return it.
        // If you don't want to send de data return `nil`
        let string = "BLE>MQTT 0x" + data.geenyHexEncodedString()
        self.displayIncomingAndOutgoingData(string: string)
        return data
      case .error(let e):
        print("read error: \(e)")
        return nil
      }
    }

    thing.subscribe(to: subscribeCharacteristicInfo) { [weak self] result -> Data? in
      guard let `self` = self else { return nil }
      switch result {
      case .success(let data):
        // Data is received from the Geeny cloud and written to the Thing.
        // At this point you can intercept the data to read it and optionally apply some filtering or transformation.
        // If you want to write the data as received just return it.
        // If you don't want to write de data return `nil`
        let string = "MQTT>BLE 0x" + data.geenyHexEncodedString()
        self.displayIncomingAndOutgoingData(string: string)
        return data
      case .error(let e):
        print("subscription error: \(e)")
        return nil
      }
    }
  }

  private func displayIncomingAndOutgoingData(string: String) {
    DispatchQueue.main.async {
      guard let textView = self.characteristicsValuesTextView else { return }
      let timeStamp = self.dateFormatter.string(from: Date())
      textView.text = """
      \(textView.text!)
      \(timeStamp) \(string)
      """
      // if the textView scrolling is close to the bottom, we scroll to the end of it after adding the new lines
      if textView.contentOffset.y + textView.frame.size.height >= textView.contentSize.height - 90 {
        textView.scrollRangeToVisible(NSMakeRange(textView.text!.count-1, 0))
      }
    }
  }

  @IBAction func registerButtonDidTap(_ sender: UIButton) {
    guard let thingInfo = thingInfo else {
      return
    }

    guard Gateway.shared.isLoggedIn else {
      AlertUtils.presentPleaseLoginAlert(in: self)
      return
    }

    if Gateway.shared.isThingRegistered(thingInfo: thingInfo) {
      AlertUtils.presentAlert(in: self, title: "Coming Soon", message: "Not supported yet.")
    } else {
      AlertUtils.presentEnterNameAlert(in: self, thingInfo: thingInfo, registerAction: { name in
        self.startRegistrationProcess(userGivenName: name, thingInfo: thingInfo)
      })
    }
  }

  private func startRegistrationProcess(userGivenName: String, thingInfo: ThingInfo) {
    let hud = MBProgressHUD.showAdded(to: view, animated: true)
    hud.label.text = "Registering"

    let updatedThingInfo = thingInfo.updatedWith(autoPublish: self.autoPublishSwitch.isOn)
    Gateway.shared.registerThing(userGivenName: userGivenName, thingInfo: updatedThingInfo) { result in
      switch result {
      case .success(let thing):
        DispatchQueue.main.async {
          hud.hide(animated: true)
          self.updateThingName(thingInfo: thing.info)
          self.updateRegistration(thingInfo: thing.info)
        }
      case .error(let e):
        print("reg error: \(e)")
        switch e {
        case APIError.invalidCredentials:
          // Token revoked. User needs to log in again.
          Gateway.shared.logout()
          if let login = self.storyboard?.instantiateViewController(withIdentifier: StoryboardIdentifier.loginNavigationController) {
            DispatchQueue.main.async {
              hud.hide(animated: true)
              self.present(login, animated: true) {
                AlertUtils.presentTokenRevokedAlert(in: login)
              }
            }
          }
        default:
          DispatchQueue.main.async {
            hud.hide(animated: true)
            AlertUtils.presentCannotRegisterAlert(in: self, error: e)
          }
        }
      }
    }
  }

}
