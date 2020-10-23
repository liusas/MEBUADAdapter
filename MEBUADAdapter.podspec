#
# Be sure to run `pod lib lint MEBUADAdapter.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MEBUADAdapter'
  s.version          = '1.0.11'
  s.summary          = 'A adapter of BUAD for mediation SDK'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = "this is a Mobiexchanger's advertise adapter, and we use it as a module"

  s.homepage         = 'https://github.com/liusas/MEBUADAdapter.git'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '刘峰' => 'liufeng@mobiexchanger.com' }
  s.source           = { :git => 'https://github.com/liusas/MEBUADAdapter.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

  s.source_files = 'MEBUADAdapter/Classes/**/*'
#  s.vendored_framework = 'MEBUADAdapter-1.0.9/ios/*.framework'
  
  # s.resource_bundles = {
  #   'MEBUADAdapter' => ['MEBUADAdapter/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
#   s.dependency 'AFNetworking', '~> 2.3'
  s.dependency "Bytedance-UnionAD", '3.2.6.2'
  s.dependency "MEAdvSDK", '~> 1.0.15'
end
