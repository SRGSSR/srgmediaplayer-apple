source 'ssh://git@bitbucket.org/rtsmb/srgpodspecs.git'
source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '7.0'

inhibit_all_warnings!

workspace 'RTSMediaPlayer'
link_with 'RTSMediaPlayerTests', 'RTSMediaPlayer Demo'

target 'RTSMediaPlayer' do
  pod 'libextobjc/EXTScope', '0.4.1'
  pod 'TransitionKit',       '2.2.0'
end

target 'RTSMediaPlayerTests' do
  pod 'libextobjc/EXTScope', '0.4.1'
  pod 'TransitionKit',       '2.2.0'
  pod 'MAKVONotificationCenter', '0.0.2'
end

target 'RTSMediaPlayer Demo' do
  xcodeproj 'RTSMediaPlayer Demo/RTSMediaPlayer Demo.xcodeproj'
  pod 'CocoaLumberjack', '2.0.0'
  pod 'SDWebImage', '3.7.0'
end
