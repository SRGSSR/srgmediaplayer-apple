Getting started
===============

The SRG Media Player library is made of separate building blocks. Those components can be combined together depending on your application needs.

## Architecture

At the highest level, the library intends to provide a default player view controller which can be instantiated in a few keystrokes, much like the system `MPMoviePlayerViewController`. It supports only limited features of the library and its layout, similar to the one of the system player, cannot be customized.

This default player view controller is itself based on a set of components which you can combine to match your requirements:

* A media player controller, which can be optionally attached to a view for playing videos
* A segments controller, which controls playback based on segment information (e.g. preventing seeking in blocked segments)
* A set of components (slider, play / pause button, timeline, message view, Airplay view, etc.) which can be connected to an underlying media player controller
* A few protocols which describe how controllers retrieve the data they need, and how playback can be controlled

Let us now discuss these components further and describe how they are glued together.

## Media player view controller

If you do not need to customize the player appearance, simply instantiate `RTSMediaPlayerViewController` and install it somewhere into your view controller hierarchy, e.g. modally:

```
#!objective-c
RTSMediaPlayerViewController *mediaPlayerViewController = [[RTSMediaPlayerViewController alloc] initWithContentURL:contentURL];
[self presentViewController:mediaPlayerViewController animated:YES completion:nil];
```

The player can simply be supplied the URL to be played. Alternatively, you can provide a data source and an identifier for which the URL must be retrieved from the data source. More on this topic in _Data sources_ section.

The `RTSMediaPlayerViewController` class natively supports all kind of audio and video streams (VOD, live and DVR streams), but does not provide support for segments. For this you need to design your own player view, see the _Designing custom players_ section below.

## Data sources

Each controller class has an associated protocol describing how it is fed with data. Controllers are only concerned with media identifiers (strings), for which they ask their data source about data:

* `RTSMediaPlayerControllerDataSource`: Describes how a media player controller retrieves the URL to be played
* `RTSMediaSegmentsDataSource`: Describes how a media segments controller retrieves segment information. Segments can be any kind of class conforming to the `RTSMediaSegment` protocol

A data source is implicitly provided to an `RTSMediaPlayerViewController` when it is instantiated (see example in the _Media player view controller_ section).

For `RTSMediaPlayerController` and `RTSMediaSegmentsController`, the data source is not provided at creation time, rather specified using dedicated `dataSource` properties. Those have been made available as outlets. The SRG Media Player library namely intends to provide an easy way to create custom player layouts not only in code, but also in Interface Builder for convenience. This topic is discussed further in the next section.

## Designing custom players

## Components

If 
