Migrating from version 1.x to version 2
=======================================

Version 2 of the SRG Media Player library introduces several changes which require you to migrate your existing code base. 

## Carthage

Support for CocoaPods has been removed. Since the framework requires at least iOS 8, using CocoaPods does not make sense anymore. Carthage is both simple and elegant, and will therefore be used in the future for integration into your project. Refer to the [official documentation](https://github.com/Carthage/Carthage) for more information about how to use the tool (don't be afraid, this is very simple).

## Prefix changes

For historical reasons, all classes were prefixed with `RTS`, which was misleading. This prefix has now been replaced with `SRG`. Be sure to update existing references in your code, xibs or storyboards (a simple text search suffices).

## Name changes

For consistency (and beside the prefix change), some classe, protocols and notifications were also renamed:

* `RTSAirplayOverviewView` is now `SRGAirplayView`
* `RTSMediaPlayerPlaybackButton` is now `SRGPlaybackButton`
* `RTSMediaSegment` is now `SRGSegment`
* Notifications in `SRGMediaPlayerConstants.h` have been made more consistent

## Reduced complexity

The original player implementation was making use of data sources, both to retrieve the content URL to be played as well as any segments associated with it. This additional content retrieval phase was adding complexity to the player:

* The player required a mechanism to cancel content retrieval (e.g. when playing some content while another one was already being loaded). Proper cancellation was difficult to guarantee, leading to subtle issues
* Internal player state management had to take into account this special phase, leading to potential state management issues

To solve those problems and make the overall use of the player controller simple, loading URLs and segments is now the responsibility of the client application. Once URL and segments have been retrieved, they are simply supplied when calling a _play_ or _prepareToPlay_ method. This way, there is no need for additional state management or content loading mechanism within the player. As a result, the state of the player controller now only reflects playback status, and data sources have been completely removed.

## Player controller creation

Previously, you had to instantiate a player controller and maybe an associated segments controller. You then had to bind together as well as to data sources. This was leading to potential issues since both controllers were independent, yet somehow related.

The segments controller has been completely removed and segment management is now entirely made by the player controller itself. As a result, playing a media with or without segments is now straightforward:

* Instantiate a player controller (no need for another segments controller anymore)
* For videos, install its `view` property into your view hierarchy. The `-attachPlayerToView:` method has been removed, you now directly install the view as subview. Even faster, you can now bind it to a view directly in your storyboard or xib file and set constraints directly there.
* Play the content

## Playback management

Playback management is now straightforward and consistent. You can basically cover any use cases by combining one or several of the following operations:

* Prepare any URL without playing it yet
* Toggle play or pause playback
* Seek
* Stop or reset the player

Several convenience methods are also provided to match the most common uses, e.g. preparing and starting playback at some specific point in time, or simply playing a URL from the start.

## Overlays

No basic overlay management is now provided by the media player controller. This was adding unnecessary complexity, and could require a whole lot of customization hooks to cover animation potential strategies (e.g. fade in or fade out, constraint changes, etc.). Since UI management is mostly the responsibility of the client application, overly management is now its responsibility entirely. To detect user activity, `SRGActivityGestureRecognizer` has now been exposed publicly.

## Physical segments

Since the player controller interface now accepts URLs to be played, supporting physical segments was not making sense anymore. A physical segment namely corresponds to a different URL being played, with different logical segments. 

As a result, the SRG Media Player library now only supports logical segments. Clients which need to display several different medias in a timeline must not use `SRGTimelineView` anymore: They should simply create their own presentation view, e.g. using a simple collection view.
