#
# Be sure to run `pod lib lint Stinger.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Stinger'
  s.version          = '1.0.0'
  s.summary          = 'Implementing HOOK & AOP using libffi for Objective-C.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/eleme/Stinger'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Assuner-Lee' => 'yongguang.li@ele.me' }
  s.source           = { :git => 'https://github.com/eleme/Stinger.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
  }
  s.default_subspecs = 'Core', 'libffi'
  # libffi source code from https://github.com/libffi/libffi
  # version 3.3.0
  # how to fix libffi, you can see https://juejin.cn/post/6955652447670894606
  s.subspec 'libffi' do |d|
    d.source_files = 'Stinger/libffi/**/*.{h,c,m,S}'
    d.public_header_files = 'Stinger/libffi/**/*.{h}'
  end
  
  s.subspec 'Core' do |d|
    d.source_files = 'Stinger/Classes/**/*'
    d.public_header_files = 'Stinger/Classes/**/*.{h}'
    d.dependency 'Stinger/libffi'
  end

end
