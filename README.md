# Geeny iOS SDK
![Status](https://img.shields.io/badge/status-alpha-orange.svg?style=flat)
![Swift version](https://img.shields.io/badge/swift-4.0-orange.svg?style=flat)
![License](https://img.shields.io/badge/license-MPLv2-orange.svg?style=flat)

The Geeny iOS SDK is a collection of libraries that help iOS developers to develop apps that work with the Geeny platform. The SDK is accompanied by an example app which demonstrates its functionalities.

Currently, the iOS SDK contains the Gateway SDK.

## Geeny Gateway SDK

On a high level, the Gateway SDK allows an iOS app to become a relay between a "non-IP-enabled Thing" and the Geeny platform. It enables such a Thing to be registered with the Geeny Cloud and securely transfer data to and from the Geeny MQTT endpoint.

At this stage, we require the Things to be "Geeny-native".

### Beta notice

This SDK is still under development and is currently released as Beta. Although it has been tested,, bugs and issues may be present. Some code might require cleanup. In addition, until version 1.0 is released, we cannot guarantee that API calls will not break from one SDK version to the next. Be sure to consult the Change Log for any breaking changes / additions to the SDK.

### Glossary:

* **Thing**: A connected device that can send and receive data - a fitness tracker or a smart lamp.
* **Non-IP-enabled Thing**: A thing which does not connect directly to the Internet by design (for example, it does not have a WIFI module built in). These Things are usually low-powered.
* **Geeny-enabled Thing**: A Thing that is compliant with the Geeny Thing specs.
* **ThingInfo**: Metadata of a Thing. Represents all metadata of a Thing, including its identifier, the characteristics and Geeny Thing Info.
* **Virtual Thing**: a Thing that is fully managed by a developer and connected to the Geeny SDK manually - e.g. a HomeKit appliance or HealthKit Data

### Requirements

* Xcode 9.0 (Swift 4.0) running on macOS.
* [CocoaPods](https://guides.cocoapods.org/using/getting-started.html#installation) 1.2
* An iOS device running iOS 10 or higher. Tested on iPhone 6s (Plus) and iPhone 7 Plus. Bluetooth is not supported in Simulator; thus, a real device is needed.
* A "Geeny-native" Bluetooth LE Thing for testing the automatic data publishing. For example, the [nRF52 DK](https://www.nordicsemi.com/eng/Products/Bluetooth-low-energy/nRF52-DK). See [More Information](#more-information) below.
* Alternatively, you can create a [virtual Thing](#adding-virtual-things). In that case you will have to manually handle publishing and subscription of data.

### More Information

First, make sure your "Geeny-native" Bluetooth LE Thing is on.
If you have a Nordic nRF52 DK (PCA10040), you can flash the [DevThing firmware](https://github.com/geeny/devthing-e0) to make it "Geeny-native”.

Also, please verify that the ThingType of your Thing and its resources are set up on [Geeny Labs](https://labs.geeny.io/things/docs/).

How to use the app:
1. Log in to your Geeny account by tapping on Login button.
1. After logging in, tap on Scan button in the top bar.
1. From the list, select a ”Geeny-native” Thing indicated by the Geeny logo.
1. Tap on Register Thing and give it a name.
1. After registration, the Gateway will start publishing data to the Geeny Cloud.
*Please note that only the [MessageTypes](https://labs.geeny.io/things/docs/#/MessageTypes) defined in the [resources](https://labs.geeny.io/things/docs/#/ThingTypes/get_thingTypes__thingTypeId__resources) of this specific ThingType will be accepted by the Geeny Cloud.*



### Running the Example app

After checking out the project, you should be able to get it running on your iPhone after following these steps:

1. [Install](https://guides.cocoapods.org/using/getting-started.html#installation) CocoaPods.
1. In Terminal, change to the local repository:  `$ cd <repoRoot>`.
1. Install the dependencies: `$ pod install`.
1. In Finder, double click to open `<repoRoot>/Geeny-iOS-SDK.xcworkspace` in Xcode.
1. Select the "GatewayExample" target.
1. If you want to run on an actual device (not Simulator), update your Develop Team / certificate signing settings:

1. Select the “GatewayExample" project on the left side to open Project Settings.
1. In the General tab, Signing section, select a proper signing option.

1. In the toolbar, select your device / simulator and hit Run.


### Installation

#### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate Geeny iOS SDK into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
  # Include these until the official Swift 4 release in September 2017
  pod 'RxSwift', :git => 'https://github.com/ReactiveX/RxSwift.git', :branch => 'swift4.0'
  pod 'RxCocoa', :git => 'https://github.com/ReactiveX/RxSwift.git', :branch => 'swift4.0'

  # The MQTT library depends on the OpenSSL static library
  pod 'OpenSSL-Universal'
  # The MQTT library has to be included separately until the protocol PR is merged in
  pod 'Moscapsule', :git => 'https://github.com/geeny/Moscapsule.git'
  # The Geeny iOS SDK itself
  pod 'GeenyGateway', :git => 'https://github.com/geeny/geeny-ios-sdk.git'
end
```

Then, run the following command:

```bash
$ pod install
```

### Set up

In your code, import the GeenyGateway framework
 `import GeenyGateway`

Then you can initialize the GeenyGateway singleton object by calling:
`Gateway.shared.setUp()`

### User Login

Before a user can send and receive data from the Geeny Cloud, they have to log in into their [Geeny account]((https://labs.geeny.io/login)).

Request the username and the password from the user and pass them on to the `Gateway.shared.login()` method:

```swift
Gateway.shared.login(username: username, password: password) { result in
	switch result {
		case .success:
    		// login worked, update UI
    	case .error(let e):
    		// login failed, retry username-password?
	}
}
```
You can always check if the user is logged in by looking at the `isLoggedIn` property:

```swift
Gateway.shared.isLoggedIn
```

And of course logout:

```swift
Gateway.shared.logout()
```

### Adding Things

Once the user is logged in, they can connect their Things.
**Important note:** make sure you have your [ThingType](https://labs.geeny.io/things/docs/#/ThingTypes/post_thingTypes) and [MessageTypes](https://labs.geeny.io/things/docs/#/MessageTypes/post_messageTypes) registered on the Geeny API before you proceed with this step.

#### Adding Bluetooth LE Things

To speed up the integration process with Bluetooth LE connected devices, the GeenyGateway iOS SDK can fully take on the Bluetooth communication with the Thing. For this to work, the hardware provider must implement the Geeny BLE characteristic in the device firmware. This characteristic contains info such as the registered ThingType and the serial number of the device. The iOS GeenyGateway SDK will recognize this information, parse it and pass it on to the Cloud during the registration process.

**Scanning for Things**

```swift
Gateway.shared.scanForThings(timeout: 2.0) { result in
	switch result {
		case .success(let scannedThings):
			// scannedThings is an array of ThingInfo
			print("Found \(scannedThings.count) things")
			scannedThings.forEach { thingInfo in
          		print("\(thingInfo.peripheralId) - \(thingInfo.name)")
        	}
		case .error(let error):
			// Most likely the Bluetooth is turned off
   }
}
```

**ThingInfo**

Scanning results returns an array of `[ThingInfo]`, this instances of `ThingInfo` have only the basic info of a Thing: `name`, `periferalId` and `isGeenyNative` (which is true if the Thing advertises the Geeny specific service).

Display the scan results to the user for selection e.g. in a Table View:
```swift
func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    // Thing cells
    let cell = tableView.dequeueReusableCell(withIdentifier: “myCellIdentifier”, for: indexPath) as! ThingTableViewCell

    let thingInfo = scanResults[indexPath.row]
    let thingName = thingInfo.name
    let uuid = thingInfo.peripheralId
    let isGeenyNative = thingInfo.isGeenyNative
    let isRegistered = Gateway.shared.isThingRegistered(thingInfo: thingInfo)

    let viewModel = ThingCellViewModel(thingName: thingName, userGivenName: userGivenName, uuid: uuid, isRegistered: isRegistered, isGeenyNative: isGeenyNative)
    cell.viewModel = viewModel
    return cell
}
```

To get all information about a Thing you have to connect and discover the characteristics of the Thing. You can do this by passing your `ThingInfo` instance to the `Gateway.shared.connectAndDiscoverCharacteristics`:

```swift
Gateway.shared.connectAndDiscoverCharacteristics(for: thingInfo) { result in
	switch result {
		case .success(let thingInfo):
			// thingInfo updated with characteristics and reference to the geenyThingInfo
		case .error(let error):
			// most likely the Bluetooth is turned off
	}
}
```

**Registering Things**

Once you have a `ThingInfo` instance with characteristics and geenyThingInfo, you can register the Thing on the Geeny Cloud:

```swift
Gateway.shared.registerThing(userGivenName: userGivenName, thingInfo: thingInfo) { result in
	switch result {
		case .success(let thing):
			// the thing object can be used to publish and subscribe to data
		case .error(let e):
			// there are several possible errors, please refer to the iOS API documentation
	}
}
```

#### Adding Virtual Things

If you are already managing the Bluetooth LE devices in your app, or you would prefer to register a virtual device from HomeKit or HealthKit, please assemble a ThingInfo manually.

*Note: make sure to register ThingType and the MessageTypes/characteristics on the Geeny API in advance*!


```swift
let messageType1 = CharacteristicInfo(uuid: "2a29", description: "antigravity sensor", topic: "2a29", properties: [.read, .notify])

let messageType2 = CharacteristicInfo(uuid: "2a30", description: "force field switch”, topic: "2a30", properties: [.write])

let geenyInfo = GeenyThingInfo(protocolVersion: 1, serialNumber: serialNumberOfThing, thingType: thingTypeofThing)

let thingInfo = ThingInfo(family: .virtualThing, name:"Virtual Ship", peripheralId: uuidOfThing, geenyThingInfo: geenyInfo, characteristics: [messageType1, messageType2], autoPublish: false)

let userGivenName = “My Falcon”
```

and then the same registration like a Bluetooth device:

```swift
Gateway.shared.registerThing(userGivenName: userGivenName, thingInfo: thingInfo) { result in
	switch result {
		case .success(let thing):
			// the thing object can be used to publish
		case .error(let e):
			// there are several possible errors
			// please refer to the reference docs
	}
}
```

#### Retrieving a previously registered Thing

```swift
Gateway.shared.registeredThing(thingInfo: ThingInfo) { result in
	switch result {
		case .success(let thing):
			// the thing object can be used to publish and subscribe to data
		case .error(let e):
			// there are several possible errors
			// please refer to the iOS reference docs
	}
}
```

#### Checking if a Thing is registered

```swift
Gateway.shared.isThingRegistered(thingInfo: ThingInfo) -> Bool
```
### Publishing Thing data to the Cloud

Once you have registered a Bluetooth LE Thing, you can ask the SDK to read and publish the data for a specific `CharacteristicInfo`:

```swift
thing.readAndPublish(characteristic: characteristicInfo) { result in
	switch result {
		case .success(let data):
			// you can inspect/alter data here
			// if you return nil instead, the data won’t be sent
			return data
    	case .error(let e):
			print("Unexpected BLE read error \(e.localizedDescription)")
			return nil
	}
}
```

### Subscribing to data coming from the Cloud

Things can also receive data from the the Geeny Cloud, e.g., to control the lights or thermostats at home.

```swift
thing.subscribe(characteristic: characteristicInfo) { result in
	switch result {
		case .success(let data):
			// you can inspect/alter data here
			// the returned data is written directly to the peripheral
			return data
		case .error(let e):
			print("Unexpected MQTT subscription error \(e.localizedDescription)")
			return nil
    }
}
```
### CharacteristicInfo

The `characteristicInfo` has to reference the BLE device characteristic’s UUID.
Topic has to reference the related resource URI of your ThingType in the Geeny backend.
For convenience we're using the same on both ends.

```swift
let characteristicInfo = CharacteristicInfo(uuid: "0000CAFE-C001-DE30-CABB-785FEABCD123", description: "", topic: "0000CAFE-C001-DE30-CABB-785FEABCD123", properties: .notify)
```

### Virtual things and the data flow

Virtual things have a slightly different data flow than Bluetooth LE Things. The SDK doesn’t know when your data is ready, so to publish the data you have to use the `publishToGeeny` method:

```swift
myVirtualThing.publishToGeeny(data: myData, characteristicInfo: myCharacteristicInfo)
```

Subscription is very similar to the Bluetooth LE things, the only difference being that you have to pass the data from the completion block to your Virtual Thing yourself:

```swift
myVirtualThing.subscribe(characteristic: myCharacteristicInfo) { result in
	switch result {
		case .success(let data):
			// pass this data to your original thing
			// e.g. doing a manual CBPeripheral.writeValue
			return data
		case .error(let e):
			XCTAssert(false, "Unexpected MQTT read error")
			return nil
	}
}	
```

## iOS API documentation

The complete API documentation of the Geeny iOS SDK is available in: `<repoRoot>/GeenyGateway/Docs`

The documentation can also be generated locally using [Jazzy](https://github.com/realm/jazzy).

First install the Jazzy library:
```bash
$ gem install jazzy
```
Then, from the main repository folder you can run our custom script to generate the docs:
```bash
$ cd scripts && ruby gen_gateway_docs.ruby
```


## Not implemented yet - Coming soon

*  Background networking support and documentation
*  Automatic reconnection to registered Things
*  Complete unit test coverage of public methods
*  Carthage, Swift Package Manager and GIT submodule support
*  Examples for using HealthKit and HomeKit devices as Things
*  Repeated scan and characteristic discovery should cancel previous tasks
*  Offline handling when the Thing itself or the Geeny API are unreacheable


## License

Copyright (C) 2017 Telefónica Germany Next GmbH, Charlottenstrasse 4, 10969 Berlin.

This project is licensed under the terms of the [Mozilla Public License Version 2.0](LICENSE.md).
