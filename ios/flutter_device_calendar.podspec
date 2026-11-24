#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_device_calendar'
  s.version          = '0.0.1'
  s.summary          = 'A cross platform plugin for modifying calendars on the user\'s device (enhanced fork).'
  s.description      = <<-DESC
A cross platform plugin for modifying calendars on the user's device (enhanced fork).
                       DESC
  s.homepage         = 'https://github.com/CaughtUp-LLC/flutter_device_calendar'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.swift_version = '5.0'
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  
  s.ios.deployment_target = '8.0'
end

