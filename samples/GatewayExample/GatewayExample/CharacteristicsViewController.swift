//
//  CharacteristicsViewController.swift
//  GeenyGateway
//
//  Created by Shuo Yang on 5/15/17.
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit
import GeenyGateway

class CharacteristicsViewController: UIViewController {

  var thingInfo: ThingInfo!
  private var enablesCommands: Bool {
    return Gateway.shared.isThingRegistered(thingInfo: thingInfo)
  }

  private struct Constants {
    static let cellIdentifierCharacteristic = "CharacteristicCell"
    static let viewControllerIdentifierCommands = "CommandsViewController"
  }
  
  @IBOutlet private weak var tableView: UITableView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    reload()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    if let selected = tableView.indexPathForSelectedRow {
      tableView.deselectRow(at: selected, animated: true)
    }
  }
  
  private func reload() {
    tableView.reloadData()
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if enablesCommands {
      let characteristic = characteristicAt(indexPath)!
      pushCommandsViewController(characteristic: characteristic)
    } else {
      tableView.deselectRow(at: indexPath, animated: true)
    }
  }
  
  private func pushCommandsViewController(characteristic: CharacteristicInfo) {
    if let commandsViewController = storyboard?.instantiateViewController(withIdentifier: Constants.viewControllerIdentifierCommands) as? CommandsViewController {
      commandsViewController.characteristicInfo = characteristic
      commandsViewController.thingInfo = thingInfo
      navigationController?.pushViewController(commandsViewController, animated: true)
    }
  }
  
  private func characteristicAt(_ indexPath: IndexPath) -> CharacteristicInfo? {
    return thingInfo?.characteristics[indexPath.row]
  }
  
}

extension CharacteristicsViewController: UITableViewDataSource, UITableViewDelegate {
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return thingInfo?.characteristics.count ?? 0
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifierCharacteristic, for: indexPath)
    
    if let characteristic = characteristicAt(indexPath) {
      cell.textLabel?.text = characteristic.description
    }
    if enablesCommands {
      cell.accessoryType = .disclosureIndicator
    } else {
      cell.accessoryType = .none
    }
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    if enablesCommands {
      return nil
    } else {
      return "To send commands, please register the Thing first. Currently only Geeny-native Things are supported."
    }
  }
    
}
