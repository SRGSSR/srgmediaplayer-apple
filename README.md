![SRG Media Player logo](https://bitbucket.org/rtsmb/srgmediaplayer-ios/raw/develop/README-images/logo.png)

## About

The SRG Media Player library for iOS provides a simple way to add a universal audio / video player to any application. It provides:

* A default player with the same look & feel as the standard iOS player
* A set of overlays which can be combined to create the user interface you need
* Support for segments

## Compatibility

The library is suitable for applications running on iOS 7 and above.

## Installation

The library can be added to a project through [CocoaPods](http://cocoapods.org/). Create a `Podfile` with the following contents:

* The SRG specification repository:
    
```
#!ruby
    source 'ssh://git@bitbucket.org/rtsmb/srgpodspecs.git'
```
    
* The `SRGMediaPlayer ` dependency:
```
#!ruby
    pod 'SRGMediaPlayer', '<version>'
```

Then run `pod install` to update the dependencies.

For more information about CocoaPods and the `Podfile`, please refer to the [official documentation](http://guides.cocoapods.org/).

## License

See the [LICENSE](LICENSE) file for more information.