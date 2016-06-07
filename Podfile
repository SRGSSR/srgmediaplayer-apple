source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '7.0'
inhibit_all_warnings!

workspace 'SRGMediaPlayer'

target 'SRGMediaPlayer' do
  pod 'SRGMediaPlayer', :path => '.'
  
  target 'SRGMediaPlayerTests' do
    inherit! :search_paths

    pod 'MAKVONotificationCenter', '0.0.2'
    pod 'libextobjc/EXTScope'
    pod 'TransitionKit'
  end

  xcodeproj 'SRGMediaPlayer.xcodeproj'
end

target 'SRGMediaPlayer Demo' do
  pod 'SRGMediaPlayer', :path => '.'
  pod 'CocoaLumberjack', '2.0.0'
  pod 'SDWebImage', '3.7.0'
  
  xcodeproj 'RTSMediaPlayer Demo/SRGMediaPlayer Demo.xcodeproj'
end
