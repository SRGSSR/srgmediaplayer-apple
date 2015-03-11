Pod::Spec.new do |s|
  s.name                  = "RTSMediaPlayer"
  s.version               = "0.0.1"
  s.summary               = "Shared media player for RTS mobile apps."
  s.homepage              = "ssh://git@bitbucket.org:rtsmb/rtsmediaplayer-ios.git"
  s.authors               = { "Frédéric Humbert-Droz" => "fred.hd@me.com", "Cédric Luthi" => "cedric.luthi@rts.ch" }

  s.source                = { :git => "ssh://git@bitbucket.org:rtsmb/rtsmediaplayer-ios.git", :branch => "master", :tag => "#{s.version}" }

  s.ios.deployment_target = "7.0"
  s.requires_arc          = true

  s.source_files          = "RTSMediaPlayer"
  s.public_header_files   = "RTSMediaPlayer/*.h"
  
  s.resource_bundle       = { "RTSMediaPlayer" => ["RTSMediaPlayer/*.xib"] }

  s.dependency "TransitionKit", "2.1.1"
end
