#
# Be sure to run `pod lib lint GeenyGateway.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'GeenyGateway'
  s.version          = '0.1.0'
  s.summary          = 'The Geeny iOS SDK is a collection of libraries that help iOS developers to develop apps that work with the Geeny.io platform.'
  s.homepage         = 'https://github.com/geeny/geeny-ios-sdk'
  s.social_media_url = 'https://twitter.com/geenyio'
  s.license          = { :type => 'MPLv2', :file => 'LICENSE' }
  s.author           = { 'Geeny B2D team' => 'b2d-team@geeny.io' }
  s.source           = { :git => 'https://github.com/geeny/geeny-ios-sdk.git', :tag => s.version.to_s }

  s.platform = :ios
  s.requires_arc = true
  s.ios.deployment_target = '10.0'
  s.source_files = 'GeenyGateway/GeenyGateway/*.{swift,h,m}', 'GeenyGateway/GeenyGateway/fmemopen/*.{h,c}'
  s.framework = 'CoreBluetooth'

  s.dependency 'Moscapsule'
  s.dependency 'KeychainSwift', '~> 8.0'
  # Using Swift 4 branches support (see Podfile)
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'

  s.libraries = "ssl", "crypto"
  s.xcconfig     = {
    'LIBRARY_SEARCH_PATHS' => '"$(PODS_ROOT)/OpenSSL-Universal/lib-ios"' # workaround
  }
end
