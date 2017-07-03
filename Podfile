source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '10.0'
use_frameworks!
inhibit_all_warnings!

workspace 'Geeny-iOS-SDK.xcworkspace'

target 'GeenyGateway' do
  project 'GeenyGateway/GeenyGateway'
  pod 'Moscapsule', :git => 'https://github.com/geeny/Moscapsule.git'
  pod 'RxSwift', :git => 'https://github.com/ReactiveX/RxSwift.git', :branch => 'swift4.0'
  pod 'RxCocoa', :git => 'https://github.com/ReactiveX/RxSwift.git', :branch => 'swift4.0'
  pod 'KeychainSwift', '~> 8.0'
  pod 'OpenSSL-Universal', '1.0.2.10'

  target 'GeenyGatewayTests' do
    pod 'OHHTTPStubs/Swift', '6.0.0'
  end
end

target 'GatewayExample' do
  project 'samples/GatewayExample/GatewayExample'
  # Gateway SDK
  pod 'GeenyGateway', :path => './'
  pod 'OpenSSL-Universal', '1.0.2.10'
  # Other dependencies
  pod 'MBProgressHUD', '1.0.0'

  target 'GatewayExampleTests' do
  end
end
