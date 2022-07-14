[![SRG Media Player logo](README-images/logo.png)](https://github.com/SRGSSR/srgmediaplayer-apple)

[![GitHub releases](https://img.shields.io/github/v/release/SRGSSR/srgmediaplayer-apple)](https://github.com/SRGSSR/srgmediaplayer-apple/releases) [![platform](https://img.shields.io/badge/platfom-ios%20%7C%20tvos-blue)](https://github.com/SRGSSR/srgmediaplayer-apple) [![SPM compatible](https://img.shields.io/badge/SPM-compatible-4BC51D.svg?style=flat)](https://swift.org/package-manager) [![GitHub license](https://img.shields.io/github/license/SRGSSR/srgmediaplayer-apple)](https://github.com/SRGSSR/srgmediaplayer-apple/blob/master/LICENSE) 

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

The library is suitable for applications running on iOS 12, tvOS 12 and above. The project is meant to be compiled with the latest Xcode version.

## Contributing

If you want to contribute to the project, have a look at our [contributing guide](CONTRIBUTING.md).

## Integration

The library must be integrated using [Swift Package Manager](https://swift.org/package-manager) directly [within Xcode](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app). You can also declare the library as a dependency of another one directly in the associated `Package.swift` manifest.

## Usage

When you want to use classes or functions provided by the library in your code, you must import it from your source files first. In Objective-C:

```objective-c
@import SRGMediaPlayer;
```

or in Swift:

```swift
import SRGMediaPlayer
```

### Working with the library

To learn about how the library can be used, have a look at the [getting started guide](GETTING_STARTED.md).

### Logging

The library internally uses the [SRG Logger](https://github.com/SRGSSR/srglogger-apple) library for logging, within the `ch.srgssr.mediaplayer` subsystem. This logger either automatically integrates with your own logger, or can be easily integrated with it. Refer to the SRG Logger documentation for more information.

### Control preview in Interface Builder

Interface Builder can render custom controls dropped onto a storyboard or a xib. If you want to enable this feature for SRG Media Player controls, **copy** the `SRGMediaPlayerDesignables.m` file available from the Swift Package Manager checkout to your project and add it to your target.

When dropping a media player control (e.g. `SRGPictureInPictureButton`) onto a storyboard or xib, Xcode will now build your project in the background and render the view when it is done.

#### Remark

Since the `SRGMediaPlayerDesignables.m` must be copied to your project, you should update this file when updating the SRG Media Player library.

## Demo project

To test what the library is capable of, run the associated demo.

## License

See the [LICENSE](../LICENSE) file for more information.
