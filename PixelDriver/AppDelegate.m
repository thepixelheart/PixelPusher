//
// Copyright 2012 Jeff Verkoeyen
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "AppDelegate.h"

#import "PHAnimation.h"
#import "PHCompositeAnimation.h"
#import "PHDisplayLink.h"
#import "PHDriver.h"
#import "PHFMODRecorder.h"
#import "PHMIDIDriver.h"
#import "PHUSBNotifier.h"
#import "PHWallView.h"
#import "Utilities.h"
#import "PHMote.h"
#import "PHMoteServer.h"
#import "PHPixelDriverWindow.h"
#import "PHProcessingAnimation.h"
#import "PHProcessingServer.h"
#import "PHProcessingSource.h"
#import "PHSystem.h"
#import "PHTooltipWindow.h"
#import "PHOverlay.h"
#import "SCEvents.h"
#import "PHDualVizualizersView.h"
#import "PHLaunchpadDevice.h"
#import "PHDJ2GODevice.h"

static const CGFloat kPixelHeartPixelSize = 16;
static const CGFloat kPreviewPixelSize = 8;
static const NSTimeInterval kCrossFadeDuration = 1;
static const NSInteger kInitialPreviewAnimationIndex = 2;

typedef enum {
  PHLaunchpadModeAnimations,
  PHLaunchpadModePreview,
  PHLaunchpadModeComposite,
} PHLaunchpadMode;

AppDelegate* PHApp() {
  return (AppDelegate *)[NSApplication sharedApplication].delegate;
}

PHSystem* PHSys() {
  return PHApp().system;
}

@implementation PHGif
@end

@interface AppDelegate() <SCEventListenerProtocol>
@end

@implementation AppDelegate {
  PHPixelDriverWindow* _appWindow;

  PHDisplayLink* _displayLink;
  PHUSBNotifier* _usbNotifier;

  // Controller server
  PHMoteServer* _moteServer;

  // Processing server
  PHProcessingServer* _processingServer;

  // Tooltip
  BOOL _showingTooltip;

  // Watching changes to the filesystem.
  SCEvents* _gifFSEvents;
  SCEvents* _scriptFSEvents;

  CGContextRef _depthBitmapContext;
}

@synthesize audioRecorder = _audioRecorder;
@synthesize midiDriver = _midiDriver;
@synthesize gifs = _gifs;

- (void)loadGifs {
  NSFileManager* fm = [NSFileManager defaultManager];

  NSString* userGifsPath = [PHSys() pathForUserGifs];

  NSError* error = nil;
  NSArray* filenames = nil;
  NSString* gifsPath = PHFilenameForResourcePath(@"gifs");
  if (![fm fileExistsAtPath:userGifsPath]) {
    [fm createDirectoryAtPath:userGifsPath withIntermediateDirectories:YES attributes:nil error:nil];

    // Copy the packaged gifs into the user directory.
    filenames = [fm contentsOfDirectoryAtPath:gifsPath error:&error];
    if (nil != error) {
      NSLog(@"Error: %@", error);
      return;
    }
    for (NSString* filename in filenames) {
      NSString* gifPath = [gifsPath stringByAppendingPathComponent:filename];
      NSString* userGifPath = [userGifsPath stringByAppendingPathComponent:filename];
      [fm copyItemAtPath:gifPath toPath:userGifPath error:nil];
    }
  }

  // Read all of the user gifs.
  error = nil;
  filenames = [fm contentsOfDirectoryAtPath:userGifsPath error:&error];
  if (nil != error) {
    NSLog(@"Error: %@", error);
    return;
  }
  NSMutableArray* gifs = [NSMutableArray array];
  for (NSString* path in filenames) {
    if ([path hasPrefix:@"."]) {
      continue;
    }
    NSString* fullPath = [userGifsPath stringByAppendingPathComponent:path];
    NSImage* image = [[NSImage alloc] initWithContentsOfFile:fullPath];
    if (!image.isValid && image.representations.count > 0) {
      continue;
    }
    NSBitmapImageRep* bitmapImage = [[image representations] objectAtIndex:0];
    if ([[bitmapImage valueForProperty:NSImageFrameCount] intValue] == 0) {
      // No frames in this image.
      continue;
    }

    PHGif* gif = [[PHGif alloc] init];
    gif.image = image;
    gif.filename = path;
    [gifs addObject:gif];
  }

  for (NSUInteger i = 0; i < gifs.count; ++i) {
    NSInteger nElements = gifs.count - i;
    NSInteger n = (arc4random() % nElements) + i;
    [gifs exchangeObjectAtIndex:i withObjectAtIndex:n];
  }
  _gifs = [gifs copy];
}

- (NSArray *)gifs {
  return [_gifs copy];
}

- (void)pathWatcher:(SCEvents *)pathWatcher eventOccurred:(SCEvent *)event {
  if (_gifFSEvents == pathWatcher) {
    [self loadGifs];
  }
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
  _displayLink = [[PHDisplayLink alloc] init];
  _animationDriver = _displayLink.systemState;

  _system = [[PHSystem alloc] init];

  _moteServer = [[PHMoteServer alloc] init];
  _processingServer = [[PHProcessingServer alloc] init];
  [self loadGifs];

  _gifFSEvents = [[SCEvents alloc] init];
  _gifFSEvents.delegate = self;
  [_gifFSEvents startWatchingPaths:@[[PHSys() pathForUserGifs]]];

  _scriptFSEvents = [[SCEvents alloc] init];
  _scriptFSEvents.delegate = self;
  [_scriptFSEvents startWatchingPaths:@[[PHSys() pathForUserScripts]]];

  [[self audioRecorder] toggleListening];

  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self
         selector:@selector(processingSourceListDidChange:)
             name:PHProcessingSourceListDidChangeNotification
           object:nil];

  _driver = [[PHDriver alloc] init];
  _usbNotifier = [[PHUSBNotifier alloc] init];
  [self midiDriver];

  _appWindow = [[PHPixelDriverWindow alloc] initWithContentRect:CGRectMake(0, 0, 1000, 700)
                                                      styleMask:(NSTitledWindowMask
                                                                 | NSClosableWindowMask
                                                                 | NSMiniaturizableWindowMask
                                                                 | NSResizableWindowMask)
                                                        backing:NSBackingStoreBuffered
                                                          defer:YES];
  _appWindow.title = @"Pixel Pusher";
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [_appWindow makeKeyAndOrderFront:self];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
  return YES;
}

#pragma mark - Public Accessors

- (PHFMODRecorder *)audioRecorder {
  if (nil == _audioRecorder) {
    _audioRecorder = [[PHFMODRecorder alloc] init];
  }
  return _audioRecorder;
}

- (PHMIDIDriver *)midiDriver {
  if (nil == _midiDriver) {
    _midiDriver = [[PHMIDIDriver alloc] init];
  }
  return _midiDriver;
}

#pragma mark - Public Methods

- (NSArray *)allMotes {
  return _moteServer.allMotes;
}

- (CGContextRef)kinectColorBitmapContext {
  return _depthBitmapContext;
}

- (void)tick {

}

- (void)didTick {
  [_moteServer didTick];
}

@end
