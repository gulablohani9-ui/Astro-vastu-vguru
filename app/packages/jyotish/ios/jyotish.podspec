Pod::Spec.new do |s|
  s.name             = 'jyotish'
  s.version          = '1.0.0'
  s.summary          = 'Vedic astrology calculations using Swiss Ephemeris.'
  s.description      = 'Flutter library for Vedic astrology using Swiss Ephemeris.'
  s.homepage         = 'https://github.com/rajsanjib/jyotish-flutter-library'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Sanjib Acharya' => 'rajsanjib@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.vendored_frameworks = 'Frameworks/swisseph.xcframework'
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.swift_version = '5.0'
end
