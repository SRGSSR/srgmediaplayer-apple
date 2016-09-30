//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLogger.h"

#define SRGMediaPlayerLogVerbose(category, format, ...) SRGLogVerbose("ch.srgssr.mediaPlayer", category, format, ##__VA_ARGS__)
#define SRGMediaPlayerLogDebug(category, format, ...)   SRGLogLogDebug("ch.srgssr.mediaPlayer", category, format, ##__VA_ARGS__)
#define SRGMediaPlayerLogInfo(category, format, ...)    SRGLogInfo("ch.srgssr.mediaPlayer", category, format, ##__VA_ARGS__)
#define SRGMediaPlayerLogWarning(category, format, ...) SRGLogWarning("ch.srgssr.mediaPlayer", category, format, ##__VA_ARGS__)
#define SRGMediaPlayerLogError(category, format, ...)   SRGLogError("ch.srgssr.mediaPlayer", category, format, ##__VA_ARGS__)
