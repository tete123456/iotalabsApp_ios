# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'
source 'https://github.com/CocoaPods/Specs.git'
target 'Lotalabs' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Lotalabs
	#추가할 라이브러리들 
  pod 'MaterialComponents/Buttons'
  pod 'JJFloatingActionButton'
  pod 'RealmSwift', '~>10'
  pod 'GoogleMaps', '4.0.0'
  pod  'Google-Maps-iOS-Utils' ,  '~> 4.0.0'
  pod 'Firebase/Messaging'
  pod 'Firebase/InAppMessaging'
  pod 'Firebase/Database'
  pod 'Firebase/Analytics'
  pod 'Firebase/Core'
  pod 'ARCL'

  target 'LotalabsTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'LotalabsUITests' do
    # Pods for testing
  end
post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
  end
end
end
