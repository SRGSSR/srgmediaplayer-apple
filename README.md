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

The library can be added to a project using [Carthage](https://github.com/Carthage/Carthage)  by adding the following dependency to your `Cartfile`:
    
```
github "SRGSSR/SRGMediaPlayer-iOS"
```

Then run `carthage update` to update the dependencies. You will need to manually add the `.framework` generated in the `Carthage/Build/iOS` folder to your projet. Refer to the [official documentation](https://github.com/Carthage/Carthage) for more information.

## Demo project

To test what the library is capable of, try running the associated demo by opening the workspace and building the associated scheme.

## Usage

To learn about how the library can be used, have a look at the [getting started guide](Documentation/Getting-started.md).

## License

See the [LICENSE](LICENSE) file for more information.
