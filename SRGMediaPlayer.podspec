Pod::Spec.new do |s|
  s.name                  = "SRGMediaPlayer"
  s.version               = "1.7.2"
  s.summary               = "Shared media player for SRG mobile apps."
  s.homepage              = "https://github.com/SRGSSR/SRGMediaPlayer-iOS"
  s.authors               = { "Frédéric Humbert-Droz" => "fred.hd@me.com", "Cédric Luthi" => "cedric.luthi@rts.ch", "Cédric Foellmi" => "cedric@onekilopars.ec", "Samuel Défago" => "defagos@gmail.com", "Pierre-Yves Bertholon" => "py.bertholon@gmail.com" }
  s.license	              = { :type => 'MIT' }

  s.source                = { :git => "https://github.com/SRGSSR/SRGMediaPlayer-iOS.git", :branch => "master", :tag => "#{s.version}" }

  s.ios.deployment_target = "7.0"
  s.requires_arc          = true

  s.source_files          = "RTSMediaPlayer"
  s.public_header_files   = "RTSMediaPlayer/*.h"
  s.private_header_files  = "RTSMediaPlayer/*+Private.h"

  s.resource_bundle       = { "SRGMediaPlayer" => [ "RTSMediaPlayer/*.xib", "RTSMediaPlayer/*.png", "RTSMediaPlayer/*.lproj" ] }

  s.dependency "libextobjc/EXTScope", "~> 0.4.1"
  s.dependency "TransitionKit",       "~> 2.2.0"

  s.subspec 'Version' do |ve|
    ve.source_files = "RTSMediaPlayer/RTSMediaPlayerVersion.m","RTSMediaPlayer/RTSMediaPlayerVersion.h"
    ve.compiler_flags = '-DRTS_MEDIA_PLAYER_VERSION=' + s.version.to_s
  end
end
