require 'json'
package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "RNTusClient"
  s.version      = package['version']
  s.summary      = package["description"]
  s.requires_arc = true
  s.license      = package["license"]
  s.homepage     = 'https://github.com/vinzscam/react-native-tus-client'
  s.author       = { "Vincenzo Scamporlino" => "vincenzo@scamporlino.it" }
  s.source       = { :git => "https://github.com/vinzscam/react-native-tus-client", :tag => 'v#{s.version}'}
  
  # Include both Objective-C and Swift files
  s.source_files = 'ios/*.{h,m,swift}'
  
  # Set the Swift version
  s.swift_version = '5.0'
  
  # Minimum iOS version
  s.ios.deployment_target = '11.0'

  s.dependency 'React-Core'
  s.dependency 'TUSKit'

  # Add post_install hook to modify Info.plist
  s.post_install do |installer|
    installer.pods_project.targets.each do |target|
      if target.name == 'RNTusClient'
        target.build_configurations.each do |config|
          # Add Info.plist modifications
          config.build_settings['INFOPLIST_KEY_BGTaskSchedulerPermittedIdentifiers'] = ['io.tus.uploading']
          config.build_settings['INFOPLIST_KEY_UIBackgroundModes'] = ['processing']
        end
      end
    end
  end
end
