platform :ios, '7.0'

inhibit_all_warnings!

workspace 'RTSMediaPlayer'

target 'RTSMediaPlayer' do
  pod 'CocoaLumberjack',     '~> 2.0.0'
  pod 'libextobjc/EXTScope', '0.4.1'
  pod 'TransitionKit',       { :git => 'https://github.com/0xced/TransitionKit.git', :commit => '6874dea2229bdefb89f6c8f708f1fae467ee5ba2' }
end

target 'RTSMediaPlayerTests' do
  pod 'CocoaLumberjack',     '~> 2.0.0'
  pod 'libextobjc/EXTScope', '0.4.1'
  pod 'TransitionKit',       { :git => 'https://github.com/0xced/TransitionKit.git', :commit => '6874dea2229bdefb89f6c8f708f1fae467ee5ba2' }
  pod 'MAKVONotificationCenter', '0.0.2'
end

target 'RTSMediaPlayer Demo' do
  xcodeproj 'RTSMediaPlayer Demo/RTSMediaPlayer Demo.xcodeproj'
  pod 'SDWebImage', '3.7.0'
end
