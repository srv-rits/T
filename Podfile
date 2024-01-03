use_frameworks!

target 'T' do
  platform :ios, '13.0'
  pod 'Bip39.swift', '~> 0.2'
  pod 'UncommonCrypto'
  pod 'Sr25519', '~> 0.2'
  pod 'Blake2', '~> 0.1.2'
  pod 'Base58Swift', '~>2.1.10'
  target 'TTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      end
    end
  end
end
