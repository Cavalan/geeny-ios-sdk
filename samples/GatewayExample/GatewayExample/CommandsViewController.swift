//
//  CommandsViewController.swift
//  GeenyGateway
//
//  Created by Shuo Yang on 5/16/17.
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit
import GeenyGateway
import CoreBluetooth

class CommandsViewController: UIViewController {
  var thingInfo: ThingInfo?
  var characteristicInfo: CharacteristicInfo?
  var thing: Thing?
  
  @IBOutlet weak var characteristicIdLabel: UILabel!
  @IBOutlet weak var thingIdLabel: UILabel!
  
  @IBOutlet weak var readButton: UIButton!
  @IBOutlet weak var write0Button: UIButton!
  @IBOutlet weak var write1Button: UIButton!
  @IBOutlet weak var subscribeSwitch: UISwitch!
  @IBOutlet weak var valueTextView: UITextView!
  
  private var characteristic: CBCharacteristic?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    assert(thingInfo != nil)
    assert(characteristicInfo != nil)

    guard let characteristicInfo = characteristicInfo else {
      return
    }
    
    updateControls(characteristicInfo: characteristicInfo)
    characteristicIdLabel.text = characteristicInfo.description
  }
    
  private func updateControls(characteristicInfo: CharacteristicInfo) {
    let readable = characteristicInfo.properties.contains(.read)
    let writable = characteristicInfo.properties.contains(.write)
    let subscribable = characteristicInfo.properties.contains(.notify)
    
    self.readButton.isEnabled = readable
    self.write0Button.isEnabled = writable
    self.write1Button.isEnabled = writable
    self.subscribeSwitch.isEnabled = subscribable
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    subscribeToCharacteristic(subscribes: false)
  }
  
  @IBAction func readButtonDidTap(_ sender: UIButton) {
    guard let characteristicInfo = characteristicInfo else {
      return
    }
    Gateway.shared.registeredThing(thingInfo: thingInfo!) { thing in
      guard let thing = thing else { return }
      thing.readAndPublish(characteristicInfo) { result -> Data? in
        switch result {
        case .success(let data):
          self.handleBluetoothReadResult(data)
          // the data will be sent to Geeny Cloud
          return data
        case .error(let e):
          print("read error: \(e)")
          return nil
        }
      }
    }
  }
  
  private func handleBluetoothReadResult(_ data: Data) {
    let hex = data.geenyHexEncodedString()
    self.valueTextView.text = "0x\(hex)"
  }
  
  @IBAction func write0ButtonDidTap(_ sender: UIButton) {
  }
  
  @IBAction func write1ButtonDidTap(_ sender: UIButton) {
  }
  
  @IBAction func notificationSwitchValueDidChange(_ sender: UISwitch) {
    subscribeToCharacteristic(subscribes: sender.isOn)
  }
  
  private func subscribeToCharacteristic(subscribes: Bool) {
  }
    
}


