Getting started
===============

The SRG Media Player library is made of separate building blocks. Those components can be combined together depending on your application needs.

## Architecture

At the highest level, the library intends to provide a default player view controller which can be instantiated in a few keystrokes, much like `MPMoviePlayerViewController`. This view controller supports only limited features of the library and its layout, similar to the one of the system player, cannot be customized.

This default player view controller is itself based on a set of components which you can combine and tailor to your needs:

* A media player controller, which can be attached to a view when playing videos
* A segments controller, which controls playback based on segment information (e.g. preventing seeking in blocked segments)
* A set of components (slider, play / pause button, timeline, message view, Airplay view, etc.) which can be connected to a controller
* A few protocols which describe how a controllers retrieve the data they need, and how playback can be controlled

## Media player view controller

If you do not need to customize the player appearance, simply instantiate `RTSMediaPlayerViewController` and install it somewhere into your view controller hierarchy, e.g. modally:

```
#!objective-c
RTSMediaPlayerViewController *mediaPlayerViewController = [[RTSMediaPlayerViewController alloc] initWithContentURL:contentURL];
[self presentViewController:mediaPlayerViewController animated:YES completion:nil];
```

The player can simply be supplied the URL to be played. Alternatively, you can provide a data source and an identifier for which the URL must be retrieved from the data source. More on this topic in the next section.

The `RTSMediaPlayerViewController` class natively supports any kind of streams (VOD, live and DVR streams), but does not provide support for segments. If you need support for segments, you need to design your own player view, see the _Designing custom players_ section below.

## Data sources



## Designing custom players

## Components

If 
