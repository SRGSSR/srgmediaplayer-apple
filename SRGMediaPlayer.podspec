Pod::Spec.new do |s|
  s.name                  = "SRGMediaPlayer"
  s.version               = "1.5.7"
  s.summary               = "Shared media player for SRG mobile apps."
  s.homepage              = "https://github.com/SRGSSR/SRGMediaPlayer-iOS"
  s.authors               = { "Frédéric Humbert-Droz" => "fred.hd@me.com", "Cédric Luthi" => "cedric.luthi@rts.ch", "Cédric Foellmi" => "cedric@onekilopars.ec", "Samuel Défago" => "defagos@gmail.com" }
  s.license	              = { :type => 'MIT' }

  s.source                = { :git => "https://github.com/SRGSSR/SRGMediaPlayer-iOS.git", :branch => "master", :tag => "#{s.version}" }

  s.ios.deployment_target = "7.0"
  s.requires_arc          = true

  s.source_files          = "RTSMediaPlayer"
  s.public_header_files   = "RTSMediaPlayer/*.h"
  s.private_header_files  = "RTSMediaPlayer/*+Private.h"

  s.resource_bundle       = { "SRGMediaPlayer" => [ "RTSMediaPlayer/Info.plist", "RTSMediaPlayer/*.xib", "RTSMediaPlayer/*.png" ] }

  s.dependency "libextobjc/EXTScope", "~> 0.4.1"
  s.dependency "TransitionKit",       "~> 2.2.0"
end
