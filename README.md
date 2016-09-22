![SRG Media Player logo](README-images/logo.png)

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) ![Platform](https://img.shields.io/cocoapods/p/CoconutKit.svg) [![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/SRGSSR/SRGMediaPlayer-iOS/master/LICENSE)

## About

The SRG Media Player library for iOS provides a simple way to add a universal audio / video player to any application. It provides:

* A default player with the same look & feel as the standard iOS player, and automatic support for picture in picture for compatible devices
* A set of overlays which can be combined to create the user interface you need
* Support for segments. Those are simply sections of a video, defined by non-overlapping time ranges, which can be blocked or hidden
* Support for DVR streams
* Ability to use several instances of the player at the same time

## Compatibility

The library is suitable for applications running on iOS 8 and above. The project is meant to be opened with the latest Xcode version (currently Xcode 8).

## Installation

The library can be added to a project using [Carthage](https://github.com/Carthage/Carthage)  by adding the following dependency to your `Cartfile`:
    
```
github "SRGSSR/SRGMediaPlayer-iOS"
```

Then run `carthage update` to update the dependencies. You will need to manually add the following `.framework`s generated in the `Carthage/Build/iOS` folder to your projet:

* `SRGMediaPlayer.framework`
* `libextobjc.framework`

For more information about Carthage and its use, refer to the [official documentation](https://github.com/Carthage/Carthage).

## Usage

When you want to classes or functions provided by the library in your code, you must import it from your source files first.

### Usage from Objective-C source files

Import the global header file using:

```objective-c
#import <SRGMediaPlayer/SRGMediaPlayer.h>
```

or directly import the module itself:

```objective-c
@import SRGMediaPlayer;
```

### Usage from Swift source files

Import the module where needed:

```swift
import SRGMediaPlayer
```

### Working with the library

To learn about how the library can be used, have a look at the [getting started guide](Documentation/Getting-started.md).

## Demo project

To test what the library is capable of, try running the associated demo by opening the workspace and building the associated scheme.

## Migration from versions 1.x

For information about changes introduced with version 2 of the library, please read the [migration guide](Documentation/Migration-guide.md).

## License

See the [LICENSE](LICENSE) file for more information.
