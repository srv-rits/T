use_frameworks!

target 'T' do
  platform :ios, '13.0'
  pod 'CommonSwift'
  pod 'HashingSwift'
  pod 'EncryptingSwift'
  pod 'ScaleCodecSwift'
  pod 'BigInt'
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
