Getting started
===============

The SRG Media Player library is made of separate building blocks:

* A core `AVPlayer`-based controller to play medias, optionally with support for a logical playback structure (segments).
* A set of overlays to be readily used with it.

Those components can be combined together depending on your application needs. A ready-to-use player view controller is also provided.

## Architecture

At the highest level, the library intends to provide a default player view controller which can be instantiated in a few keystrokes, much like the system `AVPlayerViewController`. It supports only limited features and its layout is similar to the one of the system player, but cannot be customised.

This default player view controller is itself based on a set of lower-level components which you can combine to match your requirements:

* A media player controller, which can be optionally attached to a view for playing videos.
* A set of components (slider, play / pause button, timeline, message view, Airplay overlay, etc.) which can be connected to an underlying media player controller.

Let us now discuss these components further and describe how they can be glued together.

## Media player view controller

If you do not need to customize the player appearance, simply instantiate `SRGMediaPlayerViewController` and display it modally. The view controller exposes its underlying `controller` property, which you must use to start playback:

```objective-c
SRGMediaPlayerViewController *mediaPlayerViewController = [[SRGMediaPlayerViewController alloc] init];
[self presentViewController:mediaPlayerViewController animated:YES completion:^{
    [mediaPlayerViewController.controller playURL:contentURL];
}];
```

You can also use the `controller` property to register for playback notifications.

The `SRGMediaPlayerViewController` class natively supports all kind of audio and video streams (VOD, live and DVR streams), as well as picture in picture for compatible devices. Segments are currently supported (notifications will be received for them) but not displayed. If you need to display segments, implement a custom player.

## Designing custom players

Custom player layouts can be designed entirely in Interface Builder, whether you are using xibs or storyboards. You can create your custom player entirely in code if you want, but using Interface Builder is recommended.

![Connecting outlets](Getting-started-images/outlets.jpg)

Start by adding a view controller to a storyboard file, and drop a custom object from Xcode _Utilities_ panel:

![Custom objects](Getting-started-images/custom-objects.jpg)

Set its class to `SRGMediaPlayerController`. This controller object will manage playback of medias.

Creating the player layout is then a matter of dropping more views onto the layout, setting their constraints, and connecting them to the media player controller:

* To set where the player controller must display videos (if you want to play videos), add a view to your hierarchy, set its class to `SRGMediaPlayerView`, and bind it to the media player controller `view` property.
* To control playback, you can drop one of the available overlay classes and bind their `mediaPlayerController` property directly in Interface Builder. No additional setup (except for appearance and constraints) is ususally required, as those components are automatically synchronized with the controller they have been attached to. Built-in overlay classes include most notably:
  * `SRGPlaybackButton`: A play / pause button.
  * `SRGTimeSlider`: A time slider with elapsed and remaining time label support.
  * `SRGPlaybackActivityIndicatorView`: An activity indicator.

For a more thorough description of the player controller and the associated overlays, have a look at the documentation available from the `SRGMediaPlayerController` header file.

To start playback, bind your media player controller to a `mediaPlayerController` outlet of your view controller class and start playback soon enough, for example:

```objective-c
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([self isMovingToParentViewController] || [self isBeingPresented]) {
        NSURL *mediaURL = [NSURL URLWithString:@"http://..."];
        [self.mediaPlayerController playURL:mediaURL];
    }
}
```

This is it. If you then bound a playback button or a slider to the player controller using Interface Builder, you should readily be able to control playback as well.

## Displaying segments

To display segments, you must first have a class conform to the `SRGSegment` protocol, which captures the definition of a segment:

* Segments correspond to a time range for the media URL being played.
* Segments can be optionally blocked to prevent users from seing them.

Once you have segments, simply supply them to the player controller when playing a URL:

```objective-c
[self.mediaPlayerController playURL:mediaURL withSegments:segments];
```

Note that overlapping segments are not supported yet and lead to undefined behavior.

The player controller will then emit notifications when segments are being played and skip over blocked ones.

You can display segments using dedicated built-in overlay classes you can drop onto your view controller layout and bind to your media player controller:

* `SRGTimelineSlider`: A timeline displaying segment start points and providing a way to seek with a single tap. You can use a delegate protocol to display custom icons if you want.
* `SRGTimelineView`: A horizontal list of cells displaying segments, used like a collection view.

Both provide a `-reloadData` method to reload segments from the associated media player controller. Please refer to their respective header documentation to learn about the delegate protocols you need to implement to respond to reload requests.

## Airplay support

Airplay configuration is entirely the responsibilty of client applications. `SRGMediaPlayerController` exposes three block hooks where you can easily configure Airplay playback settings as you see fit:

* `playerCreationBlock`: Called when the `AVPlayer` is created.
* `playerConfigurationBlock`: Called when the `AVPlayer` is created, and when a configuration reload is requested.
* `playerDestructionBlock`: Called when the `AVPlayer` is released.

To add basic Airplay support to your application, you can for example:

* Enable the corresponding background mode for your target.
* Enable `allowsExternalPlayback` (which is the default) and `usesExternalPlaybackWhileExternalScreenIsActive` (to switch to full-screen playback when mirroring is active) in the `playerConfigurationBlock`.

You can also drop an `SRGAirplayButton` onto your layout (displayed only when Airplay is available) or an `SRGAirplayView` (displaying the current route when Airplay is active).

## Audio session management

No audio session specific management is provided by the library. Managing audio sessions is entirely the responsibility of the application, which gives you complete freedom over how playback happens, especially in the background or when switching between applications. As for Airplay setup (see above), you can use the various block hooks to setup and restore audio session settings as required by your application.

For more information, please refer to the [official documentation](https://developer.apple.com/library/ios/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/Introduction/Introduction.html). Audio sessions are a somewhat tricky topic, you should therefore read the documentation well, experiment, and test the behavior of your application on a real device. 

In particular, you should ask yourself:

* What should happen when I was playing music with another app and my app is launched? Should the music continue? Maybe resume after my app stops playing?
* Do I want to be able to control Airplay playback from the lock screen or the control center?
* Do I want videos to be _listened to_ when the device is locked, maybe also when the application is in the background?

Moreover, you should check that your application behaves well when receiving phone calls (in particular, audio playback should stop).

## Control center integration

For proper integration into the control center and the lock screen, use the `MPRemoteCommandCenter` class. For everything to work properly on a device, `[[UIApplication sharedApplication] beginReceivingRemoteControlEvents]` must have been called first (e.g. in your application delegate) and your audio session category should be set to `AVAudioSessionCategoryPlayback`. For more information, please refer to the `MPRemoteCommandCenter` documentation.

Note that control center integration does not work in the iOS simulator, you will need a real device for tests.

## Thread-safety

The library is intended to be used from the main thread only.

## Further reading

This guide only scratches the surface of what you can do with the SRG Media Player library. For more information, please have a look at the demo implementations and check the header documentation (especially the `SRGMediaPlayerController` header documentation, which covers all topics extensively).
