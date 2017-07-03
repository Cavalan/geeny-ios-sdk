//
//  ThingTableViewCell.swift
//  GeenyGateway
//
//  Created by Shuo Yang on 6/20/17.
//  Copyright © 2017 Telefonica Germany Next GmbH. All rights reserved.
//

import UIKit

struct ThingCellViewModel {
  let thingName: String?
  let userGivenName: String?
  let uuid: String
  let isConnected: Bool
  let isGeenyNative: Bool
  
  // Derived
  var title: String {
    let deviceName = DisplayName.thingNameOrUnknown(thingName)
    if let userGivenName = userGivenName {
      return userGivenName + " / " + deviceName
    } else {
      return deviceName
    }
  }
  var subtitle: String {
      return uuid
  }
  var tintColor: UIColor {
    if isConnected {
      return UIColor.geenyGreen()
    } else {
      return UIColor.lightGray
    }
  }
}

class ThingTableViewCell: UITableViewCell {
  
  @IBOutlet private weak var registrationImageView: UIImageView!
  @IBOutlet private weak var titleLabel: UILabel!
  // Only available for subtitled cells.
  @IBOutlet private weak var subtitleLabel: UILabel?
  @IBOutlet var labelToGeenyNativeLogoHorizontalSpaceConstraint: NSLayoutConstraint!
  @IBOutlet weak var geenyNativeLogoImageView: UIImageView!
  
  var viewModel: ThingCellViewModel? {
    didSet {
      if let viewModel = viewModel {
        updateView(viewModel: viewModel)
      }
    }
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    titleLabel.text = nil
    subtitleLabel?.text = nil
    registrationImageView.tintColor = UIColor.white
  }
  
  private func updateView(viewModel: ThingCellViewModel) {
    titleLabel.text = viewModel.title
    subtitleLabel?.text = viewModel.subtitle
    registrationImageView.tintColor = viewModel.tintColor
    
    // Geeny-nativeness
    let isGeenyNative = viewModel.isGeenyNative
    geenyNativeLogoImageView.isHidden = !isGeenyNative
    labelToGeenyNativeLogoHorizontalSpaceConstraint.isActive = isGeenyNative
  }
  
}
