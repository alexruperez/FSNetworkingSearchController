#
# Be sure to run `pod lib lint FSNetworkingSearchController.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "FSNetworkingSearchController"
  s.version          = "0.1.6"
  s.summary          = "Foursquare search controller with suggest completion like Instagram."
  s.homepage         = "https://github.com/alexruperez/FSNetworkingSearchController"
  s.screenshots     = "https://raw.githubusercontent.com/alexruperez/FSNetworkingSearchController/master/screenshot.gif", "https://raw.githubusercontent.com/alexruperez/FSNetworkingSearchController/master/screenshot.png"
  s.license          = 'MIT'
  s.author           = { "alexruperez" => "contact@alexruperez.com" }
  s.source           = { :git => "https://github.com/alexruperez/FSNetworkingSearchController.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/alexruperez'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'

  s.frameworks = 'UIKit', 'CoreLocation'
  s.dependency 'FSNetworking', '~> 0.0'
end
