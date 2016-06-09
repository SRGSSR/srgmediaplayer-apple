source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '7.0'
inhibit_all_warnings!

workspace 'SRGMediaPlayer'

# Will be inherited by all targets below
pod 'SRGMediaPlayer', :path => '.'

target 'SRGMediaPlayer' do
  target 'SRGMediaPlayerTests' do
    # Test target, inherit search paths only, not linking
    # For more information, see http://blog.cocoapods.org/CocoaPods-1.0-Migration-Guide/
    inherit! :search_paths

    # Repeat SRGMediaPlayer podspec dependencies
    pod 'libextobjc/EXTScope'
    pod 'TransitionKit'

    # Target-specific dependencies
    pod 'MAKVONotificationCenter', '0.0.2'
  end

  xcodeproj 'SRGMediaPlayer.xcodeproj'
end

target 'SRGMediaPlayer Demo' do
  pod 'CocoaLumberjack', '2.0.0'
  pod 'SDWebImage', '3.8.0'
  
  xcodeproj 'RTSMediaPlayer Demo/SRGMediaPlayer Demo.xcodeproj'
end
