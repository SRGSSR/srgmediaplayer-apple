![SRG Media Player logo](README-images/logo.png)

## About

The SRG Media Player library for iOS provides a simple way to add a universal audio / video player to any application. It provides:

* A default player with the same look & feel as the standard iOS player, and automatic support for picture in picture for compatible devices
* A set of overlays which can be combined to create the user interface you need
* Support for segments. Those are simply sections of a video, defined by non-overlapping time ranges, which can be blocked or hidden
* Support for DVR streams
* Ability to use several instances of the player at the same time

## Compatibility

The library is suitable for applications running on iOS 8 and above.

## Installation

The library can be added to a project using [CocoaPods](http://cocoapods.org/) version 1.0 or above by adding the `SRGMediaPlayer` dependency to its `Podfile`:
    
```ruby
pod 'SRGMediaPlayer', '<version>'
```

For more information about CocoaPods and the `Podfile`, please refer to the [official documentation](http://guides.cocoapods.org/).

## Usage

### Usage from Objective-C source files

Import the global header file using

```objective-c
#import <SRGMediaPlayer/SRGMediaPlayer.h>
```

You can similarly import individual files, e.g.

```objective-c
#import <SRGMediaPlayer/RTSMediaPlayerViewController.h>
```

It you use CocoaPods with the `use_frameworks!` directive, it is easier to import the SRGMediaPlayer module itself where needed:

```objective-c
@import SRGMediaPlayer;
```

### Usage from Swift source files

If you installed SRGMediaPlayer with CocoaPods but without the `use_frameworks!` directive, import the global header from a bridging header:

```objective-c
#import <SRGMediaPlayer/SRGMediaPlayer.h>
```

If you use CocoaPods with the `use_frameworks!` directive, the SRGMediaPlayer module can be imported where needed:

```swift
import SRGMediaPlayer
```

To learn about how the library can be used, have a look at the [getting started guide](Documentation/Getting-started.md).

## Demo project

To test what the library is capable of, try running the associated demo by opening the workspace and building the associated scheme.

## License

See the [LICENSE](LICENSE) file for more information.
