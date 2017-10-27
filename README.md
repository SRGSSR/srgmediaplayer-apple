![SRG Media Player logo](README-images/logo.png)

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) ![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)

## About

The SRG Media Player library for iOS provides a simple way to add a universal audio / video player to any application. It provides:

* A default player with the same look & feel as the standard iOS player, and automatic support for picture in picture for compatible devices.
* A set of overlays which can be combined to create the user interface you need.
* Support for segments. Those are simply sections of a video, defined by non-overlapping time ranges, which can be blocked or hidden.
* Support for DVR streams.
* Ability to use several instances of the player at the same time.

## Compatibility

The library is suitable for applications running on iOS 9 and above. The project is meant to be opened with the latest Xcode version (currently Xcode 9).

## Installation

The library can be added to a project using [Carthage](https://github.com/Carthage/Carthage) by specifying the following dependency in your `Cartfile`:
    
```
github "SRGSSR/SRGMediaPlayer-iOS"
```

Then run `carthage update --platform iOS` to update the dependencies. You will need to manually add the following `.framework`s generated in the `Carthage/Build/iOS` folder to your project:

* `libextobjc`: A utility framework.
* `MAKVONotificationCenter`: A safe KVO framework.
* `SRGLogger`: The framework used for internal logging.
* `SRGMediaPlayer`: The main data provider framework.

For more information about Carthage and its use, refer to the [official documentation](https://github.com/Carthage/Carthage).

## Usage

When you want to use classes or functions provided by the library in your code, you must import it from your source files first.

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

### Logging

The library internally uses the [SRG Logger](https://github.com/SRGSSR/srglogger-ios) library for logging, within the `ch.srgssr.mediaplayer` subsystem. This logger either automatically integrates with your own logger, or can be easily integrated with it. Refer to the SRG Logger documentation for more information.

### Control preview in Interface Builder

Interface Builder can render custom controls dropped onto a storyboard or a xib. If you want to enable this feature for SRG Media Player controls, and after Carthage has been run, open the `Carthage/Checkouts/SRGMediaPlayer-iOS/Designables` directory, **copy** the `SRGMediaPlayerDesignables.m` file it contains to your project and add it to your target.

When dropping a media player control (e.g. `SRGPictureInPictureButton`) onto a storyboard or xib, Xcode will now build your project in the background and render the view when it is done.

If rendering does not work properly:

* Be sure that your project correctly compiles.
* If you still get `dlopen` errors, this means some frameworks are not available to Xcode when it runs your project for rendering. This usually means that the `copy-frameworks` build phase described in the [Carthage readme](https://github.com/Carthage/Carthage#getting-started) has not been setup properly. Be sure that all SRG Media Player dependencies are properly copied (see above framework list).

#### Remark

Since the `SRGMediaPlayerDesignables.m` must be copied to your project, you should update this file when updating the SRG Media Player library.

## Demo project

To test what the library is capable of, run the associated demo.

## Migration from versions 1.x

For information about changes introduced with version 2 of the library, please read the [migration guide](Documentation/Migration-guide.md).

## License

See the [LICENSE](LICENSE) file for more information.
