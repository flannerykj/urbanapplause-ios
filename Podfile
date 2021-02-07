# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

target 'UrbanApplause' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  # https://github.com/xmartlabs/Eureka/issues/2057
  pod 'Eureka', :git => 'https://github.com/xmartlabs/Eureka.git', :branch => 'xcode12' 
  pod 'ViewRow'
  pod 'SwiftLint'
  pod 'SnapKit'
  pod 'Cloudinary'
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'FloatingPanel'
  # Pods for UrbanApplause

  target 'UrbanApplauseUpload' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'Shared' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'UrbanApplauseTests' do
    inherit! :search_paths
    # Pods for testing
  end
end
