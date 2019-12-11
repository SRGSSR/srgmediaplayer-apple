[![SRG Media Player logo](README-images/logo.png)](https://github.com/SRGSSR/srgmediaplayer-apple)

[![GitHub releases](https://img.shields.io/github/v/release/SRGSSR/srgmediaplayer-apple)](https://github.com/SRGSSR/srgmediaplayer-apple/releases) [![platform](https://img.shields.io/badge/platfom-ios%20%7C%20tvos-blue)](https://github.com/SRGSSR/srgmediaplayer-apple) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![GitHub license](https://img.shields.io/github/license/SRGSSR/srgmediaplayer-apple)](https://github.com/SRGSSR/srgmediaplayer-apple/blob/master/LICENSE) 

## About

The SRG Media Player library provides a simple way to add universal audio / video playback support to any application. It provides:

* A controller with precise playback state information and and a simple but powerful playback API.
* Automatic integration with `AVPlayerViewController`.
* A set of overlays which can be combined to create custom player user interfaces.
* Support for subdivision of medias in (non-overlapping) sequences, which can provide am additional finer-grained playback structure or block playback to parts of the content.
* Support for on-demand, live and DVR streams.
* Support for 360° and cardboard playback.
* Ability to use several instances of the player at the same time.

## Compatibility

The library is suitable for applications running on iOS 9, tvOS 12 and above. The project is meant to be opened with the latest Xcode version.

## Contributing

If you want to contribute to the project, have a look at our [contributing guide](CONTRIBUTING.md).

## Installation

The library can be added to a project using [Carthage](https://github.com/Carthage/Carthage) by adding the following dependency to your `Cartfile`:
    
```
github "SRGSSR/srgmediaplayer-apple"
```

For more information about Carthage and its use, refer to the [official documentation](https://github.com/Carthage/Carthage).

### Dependencies

The library requires the following frameworks to be added to any target requiring it:

* `libextobjc`: A utility framework.
* `MAKVONotificationCenter`: A safe KVO framework.
* `SRGLogger`: The framework used for internal logging.
* `SRGMediaPlayer`: The main library framework.

### Dynamic framework integration

1. Run `carthage update` to update the dependencies (which is equivalent to `carthage update --configuration Release`). 
2. Add the frameworks listed above and generated in the `Carthage/Build/(iOS|tvOS|watchOS)` folder to your target _Embedded binaries_.

If your target is building an application, a few more steps are required:

1. Add a _Run script_ build phase to your target, with `/usr/local/bin/carthage copy-frameworks` as command.
2. Add each of the required frameworks above as input file `$(SRCROOT)/Carthage/Build/(iOS|tvOS|watchOS)/FrameworkName.framework`.

### Static framework integration

1. Run `carthage update --configuration Release-static` to update the dependencies. 
2. Add the frameworks listed above and generated in the `Carthage/Build/(iOS|tvOS|watchOS)/Static` folder to the _Linked frameworks and libraries_ list of your target.
3. Also add any resource bundle `.bundle` found within the `.framework` folders to your target directly.
4. Add the `-all_load` flag to your target _Other linker flags_.

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

To learn about how the library can be used, have a look at the [getting started guide](GETTING_STARTED.md).

### Logging

The library internally uses the [SRG Logger](https://github.com/SRGSSR/srglogger-ios) library for logging, within the `ch.srgssr.mediaplayer` subsystem. This logger either automatically integrates with your own logger, or can be easily integrated with it. Refer to the SRG Logger documentation for more information.

### Control preview in Interface Builder

Interface Builder can render custom controls dropped onto a storyboard or a xib. If you want to enable this feature for SRG Media Player controls, and after Carthage has been run, open the `Carthage/Checkouts/srgmediaplayer-apple/Designables` directory, **copy** the `SRGMediaPlayerDesignables.m` file it contains to your project and add it to your target.

When dropping a media player control (e.g. `SRGPictureInPictureButton`) onto a storyboard or xib, Xcode will now build your project in the background and render the view when it is done.

If rendering does not work properly:

* Be sure that your project correctly compiles.
* If you still get `dlopen` errors, this means some frameworks are not available to Xcode when it runs your project for rendering. This usually means that the `copy-frameworks` build phase described in the [Carthage readme](https://github.com/Carthage/Carthage#getting-started) has not been setup properly. Be sure that all SRG Media Player dependencies are properly copied (see above framework list).

#### Remark

Since the `SRGMediaPlayerDesignables.m` must be copied to your project, you should update this file when updating the SRG Media Player library.

## Building the project

A [Makefile](../Makefile) provides several targets to build and package the library. The available targets can be listed by running the following command from the project root folder:

```
make help
```

Alternatively, you can of course open the project with Xcode and use the available schemes.

## Demo project

To test what the library is capable of, run the associated demo.

## Migration from versions 1.x

For information about changes introduced with version 2 of the library, please read the [migration guide](MIGRATION_GUIDE.md).

## License

See the [LICENSE](../LICENSE) file for more information.
