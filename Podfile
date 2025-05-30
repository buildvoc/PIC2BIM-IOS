# Uncomment the next line to define a global platform for your project
platform :ios, '14.0'

target 'PIC2BIM' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for EGNSS4ALL
  pod 'lottie-ios'

end

post_install do |installer|
 installer.pods_project.targets.each do |target|
   target.build_configurations.each do |config|
     if config.name == 'Debug' || config.name == 'Dev' || config.name == 'Staging'
       config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'

       config.build_settings['EXCLUDED_ARCHS[sdk=iphoneos*]]'] = 'x86_64'
# Some developers are using Silicon and some are using Intel, this is why the below setting is commented to support both
#       config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'  # 'x86_64' For apple silicon

       config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf'

       config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
       config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '0'
       config.build_settings['SWIFT_COMPILATION_MODE'] = 'singlefile'
       config.build_settings['VALIDATE_PRODUCT'] = 'NO'
       config.build_settings['ENABLE_NS_ASSERTIONS'] = 'YES'
     end
   end
 end
end
