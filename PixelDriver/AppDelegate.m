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
#import "PHLaunchpadMIDIDriver.h"
#import "PHUSBNotifier.h"
#import "PHWallView.h"
#import "Utilities.h"
#import "PHMote.h"
#import "PHMoteServer.h"
#import "PHProcessingAnimation.h"
#import "PHProcessingServer.h"
#import "PHProcessingSource.h"
#import "PHTooltipWindow.h"
#import "PHOverlay.h"
#import "SCEvents.h"

static const CGFloat kPixelHeartPixelSize = 16;
static const CGFloat kPreviewPixelSize = 8;
static const NSTimeInterval kCrossFadeDuration = 1;
static const NSInteger kInitialPreviewAnimationIndex = 1;

typedef enum {
  PHLaunchpadModeAnimations,
  PHLaunchpadModePreview,
  PHLaunchpadModeComposite,
} PHLaunchpadMode;

AppDelegate *PHApp() {
  return (AppDelegate *)[NSApplication sharedApplication].delegate;
}

@interface AppDelegate() <SCEventListenerProtocol>
@end

@implementation AppDelegate {
  PHDisplayLink* _displayLink;
  PHUSBNotifier* _usbNotifier;

  NSMutableArray* _animations;
  NSMutableArray* _previewAnimations;
  NSMutableArray* _processingAnimations;
  NSMutableArray* _previewProcessingAnimations;
  NSMutableArray* _compositeAnimations;
  NSMutableArray* _previewCompositeAnimations;
  NSMutableArray *_activeOverlays;
  
  PHLaunchpadMode _launchpadMode;

  // Animation/preview top button modes
  BOOL _instantCrossfade;

  // Composite mode
  PHLaunchpadTopButton _activeCompositeLayer;
  PHCompositeAnimation* _compositeAnimationBeingEdited;
  PHCompositeAnimation* _previewCompositeAnimationBeingEdited;
  BOOL _isConfirmingDeletion;

  PHAnimation* _activeAnimation;
  PHAnimation* _previousAnimation;
  PHAnimation* _previewAnimation;
  NSTimeInterval _crossFadeStartTime;

  PHSpritesheet* _pixelHeartTextSpritesheet;

  // Controller server
  PHMoteServer* _moteServer;

  // Processing server
  PHProcessingServer* _processingServer;

  // Tooltip
  BOOL _showingTooltip;

  // Watching changes to the filesystem.
  SCEvents* _fsEvents;
}

@synthesize audioRecorder = _audioRecorder;
@synthesize midiDriver = _midiDriver;
@synthesize gifs = _gifs;

- (void)prepareWindow:(PHWallWindow *)window {
  [window setAcceptsMouseMovedEvents:YES];
  [window setMovableByWindowBackground:YES];

  NSRect frame = self.window.frame;

  CGFloat midX = NSMidX(frame);
  CGFloat midY = NSMidY(frame);

  frame.size.width = kWallWidth * window.wallView.pixelSize + (kWallWidth + 1) * kPixelBorderSize;
  frame.size.height = kWallHeight * window.wallView.pixelSize + (kWallHeight + 1) * kPixelBorderSize;
  [window setMaxSize:frame.size];
  [window setMinSize:frame.size];

  [window setFrame:NSMakeRect(floorf(midX - frame.size.width * 0.5f),
                              floorf(midY - frame.size.height * 0.5f),
                              frame.size.width,
                              frame.size.height)
           display:YES];
}

- (NSMutableArray *)createAnimations {
  NSArray* animations = [PHAnimation allAnimations];

  for (PHAnimation* animation in animations) {
    animation.driver = self.animationDriver;
  }

  return [animations mutableCopy];
}

- (NSString *)pathForUserGifs {
  NSString* userGifsPath = @"~/Library/Application Support/PixelDriver/gifs/";
  return [userGifsPath stringByExpandingTildeInPath];
}

- (void)loadGifs {
  NSFileManager* fm = [NSFileManager defaultManager];

  NSString* userGifsPath = [self pathForUserGifs];

  NSString* gifsPath = PHFilenameForResourcePath(@"gifs");
  if ([fm fileExistsAtPath:userGifsPath] == NO) {
    [fm createDirectoryAtPath:userGifsPath withIntermediateDirectories:YES attributes:nil error:nil];
  }

  NSError* error = nil;
  NSArray* filenames = [fm contentsOfDirectoryAtPath:gifsPath error:&error];
  if (nil != error) {
    NSLog(@"Error: %@", error);
    return;
  }
  for (NSString* filename in filenames) {
    NSString* gifPath = [gifsPath stringByAppendingPathComponent:filename];
    NSString* userGifPath = [userGifsPath stringByAppendingPathComponent:filename];
    [fm copyItemAtPath:gifPath toPath:userGifPath error:nil];
  }

  error = nil;
  filenames = [fm contentsOfDirectoryAtPath:userGifsPath error:&error];
  if (nil != error) {
    NSLog(@"Error: %@", error);
    return;
  }
  NSMutableArray* gifs = [NSMutableArray array];
  for (NSString* path in filenames) {
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

    [gifs addObject:image];
  }

  for (NSUInteger i = 0; i < gifs.count; ++i) {
    NSInteger nElements = gifs.count - i;
    NSInteger n = (arc4random() % nElements) + i;
    [gifs exchangeObjectAtIndex:i withObjectAtIndex:n];
  }
  _gifs = [gifs copy];
}

- (NSArray *)gifs {
  NSMutableArray* gifs = [NSMutableArray array];
  for (NSImage* gif in _gifs) {
    [gifs addObject:[gif copy]];
  }
  return gifs;
}

- (void)pathWatcher:(SCEvents *)pathWatcher eventOccurred:(SCEvent *)event {
  [self loadGifs];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
  _moteServer = [[PHMoteServer alloc] init];
  _processingServer = [[PHProcessingServer alloc] init];
  [self loadGifs];

  _fsEvents = [[SCEvents alloc] init];
  _fsEvents.delegate = self;
  [_fsEvents startWatchingPaths:@[[self pathForUserGifs]]];

  [self hideTooltip];

  [[self audioRecorder] toggleListening];

  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self
         selector:@selector(launchpadStateDidChange:)
             name:PHLaunchpadDidReceiveStateChangeNotification
           object:nil];
  [nc addObserver:self
         selector:@selector(launchpadDidConnect:)
             name:PHLaunchpadDidConnectNotification
           object:nil];
  [nc addObserver:self
         selector:@selector(displayLinkDidFire:)
             name:PHDisplayLinkFiredNotification
           object:nil];
  [nc addObserver:self
         selector:@selector(processingSourceListDidChange:)
             name:PHProcessingSourceListDidChangeNotification
           object:nil];

  self.window.wallView.pixelSize = kPixelHeartPixelSize;
  self.previewWindow.wallView.pixelSize = kPreviewPixelSize;
  [self prepareWindow:self.window];
  [self prepareWindow:self.previewWindow];
  [self.launchpadWindow setAcceptsMouseMovedEvents:YES];
  [self.launchpadWindow setMovableByWindowBackground:YES];

  // Because the two wall windows use the same views we need to let one know
  // that it's the "main" view. This main view will pipe its output to the wall.
  self.window.wallView.primary = YES;

  _driver = [[PHDriver alloc] init];
  _displayLink = [[PHDisplayLink alloc] init];
  _animationDriver = _displayLink.animationDriver;
  _usbNotifier = [[PHUSBNotifier alloc] init];
  [self midiDriver];

  _launchpadMode = PHLaunchpadModeAnimations;

  // We duplicate the arrays here for each set of animations so that each window
  // can have its own instances of animations. This is so that an animation
  // instance is only ever run once per run-loop.
  _animations = [self createAnimations];
  _previewAnimations = [self createAnimations];
  _processingAnimations = [NSMutableArray array];
  _previewProcessingAnimations = [NSMutableArray array];
  _compositeAnimations = [NSMutableArray array];
  _previewCompositeAnimations = [NSMutableArray array];
  _activeOverlays = [NSMutableArray array];
  
  // Arbitrary starting animations. Change these if you're working on animations
  // and want the startup animation to be something else.
  _activeAnimation = [_animations objectAtIndex:PHInitialAnimationIndex];
  _previewAnimation = [_animations objectAtIndex:kInitialPreviewAnimationIndex];

  _previousAnimation = nil;
  _activeCompositeLayer = 0;

  _pixelHeartTextSpritesheet = [[PHSpritesheet alloc] initWithName:@"pixelhearttext"
                                                        spriteSize:CGSizeMake(42, 7)];

  [PHAnimation setAdditionalAnimationCreator:^NSArray *{
    NSMutableArray* animations = [NSMutableArray array];
    for (PHProcessingSource* source in _processingServer.allSources) {
      PHProcessingAnimation* animation = [PHProcessingAnimation animationWithSource:source];
      [animations addObject:animation];
    }
    return [animations copy];
  }];
  [self loadComposites];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [self.window performSelector:@selector(makeKeyAndOrderFront:) withObject:self afterDelay:0.5];
  [self.previewWindow performSelector:@selector(makeKeyAndOrderFront:) withObject:self afterDelay:0.5];
  [self.launchpadWindow performSelector:@selector(makeKeyAndOrderFront:) withObject:self afterDelay:0.5];
  [self.window center];

  // Simulate a connection to the launchpad at least once, regardless of whether
  // we've actually connected. This initializes the simulator.
  [self launchpadDidConnect:nil];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
  [self saveComposites];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
  return YES;
}

#pragma mark - Saving/Loading Composites

- (NSString *)compositeFilename {
  NSFileManager *fileManager = [NSFileManager defaultManager];

  NSString *folder = @"~/Library/Application Support/PixelDriver/";
  folder = [folder stringByExpandingTildeInPath];

  if ([fileManager fileExistsAtPath:folder] == NO) {
    [fileManager createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:nil];
  }
  return [[folder stringByAppendingPathComponent:@"composites"] stringByAppendingPathExtension:@".plist"];
}

- (void)loadComposites {
  NSData* data = [NSData dataWithContentsOfFile:[self compositeFilename]];
  if (nil != data) {
    NSArray* compositeAnimations = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    for (PHCompositeAnimation* animation in compositeAnimations) {
      animation.driver = self.animationDriver;
      [_compositeAnimations addObject:[animation copy]];
      [_previewCompositeAnimations addObject:[animation copy]];
    }
  }
}

- (void)saveComposites {
  NSData* data = [NSKeyedArchiver archivedDataWithRootObject:_previewCompositeAnimations];
  if (nil != data) {
    [data writeToFile:[self compositeFilename] atomically:YES];
  }
}

#pragma mark - Public Accessors

- (PHFMODRecorder *)audioRecorder {
  if (nil == _audioRecorder) {
    _audioRecorder = [[PHFMODRecorder alloc] init];
  }
  return _audioRecorder;
}

- (PHLaunchpadMIDIDriver *)midiDriver {
  if (nil == _midiDriver) {
    _midiDriver = [[PHLaunchpadMIDIDriver alloc] init];
  }
  return _midiDriver;
}

#pragma mark - Button Indices

// Find an animation instance in any of the animation arrays and return its
// corresponding button index.
- (NSInteger)buttonIndexOfAnimation:(PHAnimation *)animation {
  if (nil == animation) {
    return -1;
  }

  // Check animation arrays.
  NSInteger buttonIndex = [_animations indexOfObject:animation];
  if (buttonIndex == NSNotFound) {
    buttonIndex = [_previewAnimations indexOfObject:animation];
  }

  // Check processing arrays.
  if (buttonIndex == NSNotFound) {
    buttonIndex = [_processingAnimations indexOfObject:animation];
    if (buttonIndex != NSNotFound) {
      buttonIndex += _animations.count;
    }
  }
  if (buttonIndex == NSNotFound) {
    buttonIndex = [_previewProcessingAnimations indexOfObject:animation];
    if (buttonIndex != NSNotFound) {
      buttonIndex += _animations.count;
    }
  }

  // Check composite arrays.
  if (buttonIndex == NSNotFound) {
    buttonIndex = [_compositeAnimations indexOfObject:animation];
    if (buttonIndex != NSNotFound) {
      buttonIndex += [self numberOfPureAnimations];
    }
  }
  if (buttonIndex == NSNotFound) {
    buttonIndex = [_previewCompositeAnimations indexOfObject:animation];
    if (buttonIndex != NSNotFound) {
      buttonIndex += [self numberOfPureAnimations];
    }
  }

  // Not in any array.
  if (buttonIndex == NSNotFound) {
    buttonIndex = -1;
  }

  return buttonIndex;
}

#pragma mark - Colors

- (void)refreshButtonColorAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex >= 0 && buttonIndex < 64) {
    PHLaunchpadMIDIDriver* launchpad = PHApp().midiDriver;
    [launchpad setButtonColor:[self buttonColorForButtonIndex:buttonIndex]
                atButtonIndex:buttonIndex];
  }
}

- (void)refreshTopButtonColorAtIndex:(PHLaunchpadTopButton)buttonIndex {
  if (buttonIndex < PHLaunchpadTopButtonCount) {
    PHLaunchpadMIDIDriver* launchpad = PHApp().midiDriver;
    [launchpad setTopButtonColor:[self topButtonColorForIndex:buttonIndex]
                         atIndex:buttonIndex];
  }
}

- (void)refreshSideButtonColorAtIndex:(PHLaunchpadSideButton)buttonIndex {
  if (buttonIndex < PHLaunchpadSideButtonCount) {
    PHLaunchpadMIDIDriver* launchpad = PHApp().midiDriver;
    [launchpad setRightButtonColor:[self sideButtonColorForIndex:buttonIndex]
                           atIndex:buttonIndex];
  }
}

- (PHLaunchpadColor)buttonColorForButtonIndex:(NSInteger)buttonIndex {
  if (buttonIndex >= [self numberOfAnimations]) {
    return PHLaunchpadColorOff;
  }

  BOOL isActiveAnimation = [self buttonIndexOfAnimation:_activeAnimation] == buttonIndex;
  BOOL isPreviousAnimation = [self buttonIndexOfAnimation:_previousAnimation] == buttonIndex;
  PHAnimation* animation = [self animationFromButtonIndex:buttonIndex];
  BOOL isPipeAnimation = animation.isPipeAnimation;

  static PHLaunchpadColor colorMatrix[3 * 3] = {
    PHLaunchpadColorGreenDim, PHLaunchpadColorGreenBright, PHLaunchpadColorGreenFlashing,
    PHLaunchpadColorRedDim, PHLaunchpadColorRedBright, PHLaunchpadColorRedFlashing,
    PHLaunchpadColorAmberDim, PHLaunchpadColorAmberBright, PHLaunchpadColorAmberFlashing
  };

  if (_launchpadMode == PHLaunchpadModeAnimations) {
    if (isPipeAnimation) {
      return PHLaunchpadColorOff;
    }

    NSInteger index = (isPreviousAnimation ? 2 : (isActiveAnimation ? 1 : 0));
    NSInteger colorOffset = ((buttonIndex % 8) / 2 + ((buttonIndex / 16) % 3)) % 3;
    return colorMatrix[colorOffset * 3 + index];

  } else if (_launchpadMode == PHLaunchpadModePreview) {
    if (isPipeAnimation) {
      return PHLaunchpadColorOff;
    }

    BOOL isPreviewAnimation = [self buttonIndexOfAnimation:_previewAnimation] == buttonIndex;

    if (!isPreviousAnimation && !isActiveAnimation && isPreviewAnimation) {
      return PHLaunchpadColorYellowBright;
    }
    NSInteger index = (isPreviousAnimation ? 2 : (isActiveAnimation ? 1 : 0));
    NSInteger colorOffset = ((buttonIndex % 8) / 2 + ((buttonIndex / 16) % 3)) % 3;
    return colorMatrix[colorOffset * 3 + index];

  } else if (_launchpadMode == PHLaunchpadModeComposite) {
    if (buttonIndex < [self numberOfPureAnimations]) {
      NSInteger activeAnimationIndex = [_previewCompositeAnimationBeingEdited indexOfAnimationForLayer:_activeCompositeLayer];

      NSInteger index = ((buttonIndex == activeAnimationIndex) ? 1 : 0);
      NSInteger colorOffset = ((buttonIndex % 8) / 2 + ((buttonIndex / 16) % 3)) % 3;
      return colorMatrix[colorOffset * 3 + index];

    } else {
      NSInteger activeCompositeIndex = [self buttonIndexOfAnimation:_previewCompositeAnimationBeingEdited];
      return (buttonIndex == activeCompositeIndex) ? PHLaunchpadColorAmberBright : PHLaunchpadColorAmberDim;
    }
  }
  return PHLaunchpadColorOff;
}

- (PHLaunchpadColor)topButtonColorForIndex:(PHLaunchpadTopButton)buttonIndex {
  if (_launchpadMode == PHLaunchpadModeAnimations
      || _launchpadMode == PHLaunchpadModePreview) {
    if (buttonIndex == PHLaunchpadTopButtonSession && _instantCrossfade) {
      return PHLaunchpadColorGreenBright;
    } else {
      return PHLaunchpadColorOff;
    }
  } else if (_launchpadMode == PHLaunchpadModeComposite) {
    NSInteger animationIndex = [_previewCompositeAnimationBeingEdited indexOfAnimationForLayer:buttonIndex];

    if (_activeCompositeLayer == buttonIndex) {
      return (animationIndex >= 0) ? PHLaunchpadColorGreenBright : PHLaunchpadColorAmberBright;
    } else {
      return (animationIndex >= 0) ? PHLaunchpadColorGreenDim : PHLaunchpadColorAmberDim;
    }

  } else {
    return PHLaunchpadColorOff;
  }
}

- (PHLaunchpadColor)sideButtonColorForIndex:(PHLaunchpadSideButton)buttonIndex {
  if (_launchpadMode == PHLaunchpadModeComposite) {
    if (buttonIndex == PHLaunchpadSideButtonSendA) {
      // If the composite animation is already in the set of animations then we
      // don't show a "save" button for it.
      BOOL editingExistingComposite = [self buttonIndexOfAnimation:_previewCompositeAnimationBeingEdited] >= 0;
      return editingExistingComposite ? PHLaunchpadColorAmberDim : PHLaunchpadColorGreenDim;

    } else if (buttonIndex == PHLaunchpadSideButtonSendB) {
      return _isConfirmingDeletion ? PHLaunchpadColorRedFlashing : PHLaunchpadColorRedDim;
    }
  }
  if (buttonIndex == PHLaunchpadSideButtonArm) {
    return (_launchpadMode == PHLaunchpadModePreview) ? PHLaunchpadColorGreenBright : PHLaunchpadColorAmberDim;

  } else if (buttonIndex == PHLaunchpadSideButtonTrackOn) {
    return (_launchpadMode == PHLaunchpadModeComposite) ? PHLaunchpadColorGreenBright : PHLaunchpadColorAmberDim;

  } else {
    return PHLaunchpadColorOff;
  }
}

#pragma mark - Launchpad

- (NSInteger)numberOfPureAnimations {
  return _animations.count + _processingAnimations.count;
}

- (NSInteger)numberOfAnimations {
  return [self numberOfPureAnimations] + _previewCompositeAnimations.count;
}

- (void)updateGrid {
  for (NSInteger ix = 0; ix < [self numberOfAnimations]; ++ix) {
    [self refreshButtonColorAtIndex:ix];
  }
}

- (void)updateTopButtons {
  for (NSInteger ix = 0; ix < PHLaunchpadTopButtonCount; ++ix) {
    [self refreshTopButtonColorAtIndex:(PHLaunchpadTopButton)ix];
  }
}

- (void)updateSideButtons {
  for (NSInteger ix = 0; ix < PHLaunchpadSideButtonCount; ++ix) {
    [self refreshSideButtonColorAtIndex:(PHLaunchpadSideButton)ix];
  }
}

- (void)updateLaunchpad {
  [self updateGrid];
  [self updateTopButtons];
  [self updateSideButtons];
}

- (void)toggleLaunchpadMode:(PHLaunchpadMode)mode {
  if (_launchpadMode == mode) {
    _launchpadMode = PHLaunchpadModeAnimations;
    [self saveComposites];

  } else {
    _launchpadMode = mode;

    if (_launchpadMode == PHLaunchpadModeComposite) {
      if (nil == _previewCompositeAnimationBeingEdited) {
        // If we're not editing one, create a default one.
        if (_compositeAnimations.count == 0) {
          _compositeAnimationBeingEdited = [PHCompositeAnimation animation];
          _compositeAnimationBeingEdited.driver = self.animationDriver;
          _previewCompositeAnimationBeingEdited = [PHCompositeAnimation animation];
          _previewCompositeAnimationBeingEdited.driver = self.animationDriver;
        } else {
          _compositeAnimationBeingEdited = [_compositeAnimations objectAtIndex:0];
          _previewCompositeAnimationBeingEdited = [_previewCompositeAnimations objectAtIndex:0];
        }
      }
    }
  }

  [self updateLaunchpad];
}

- (void)launchpadDidConnect:(NSNotification *)notification {
  PHLaunchpadMIDIDriver* launchpad = PHApp().midiDriver;
  [launchpad reset];
  [launchpad enableFlashing];
  [launchpad startDoubleBuffering];

  [self updateLaunchpad];

  [launchpad flipBuffer];
}

#pragma mark - Animations

- (PHAnimation *)animationFromButtonIndex:(NSInteger)buttonIndex {
  if (buttonIndex < _animations.count) {
    return [_animations objectAtIndex:buttonIndex];

  } else if (buttonIndex < [self numberOfPureAnimations]) {
    return [_processingAnimations objectAtIndex:buttonIndex - _animations.count];

  } else if (buttonIndex < [self numberOfPureAnimations] + _compositeAnimations.count) {
    return [_compositeAnimations objectAtIndex:buttonIndex - [self numberOfPureAnimations]];
  }

  return nil;
}

- (PHAnimation *)previewAnimationFromButtonIndex:(NSInteger)buttonIndex {
  if (buttonIndex < _animations.count) {
    return [_previewAnimations objectAtIndex:buttonIndex];

  } else if (buttonIndex < [self numberOfPureAnimations]) {
    return [_previewProcessingAnimations objectAtIndex:buttonIndex - _animations.count];

  } else if (buttonIndex < [self numberOfPureAnimations] + _compositeAnimations.count) {
    return [_previewCompositeAnimations objectAtIndex:buttonIndex - [self numberOfPureAnimations]];
  }

  return nil;
}

- (void)swapAnimationsAtButtonIndex:(NSInteger)buttonIndex {
  PHAnimation* previewAnimation = [self previewAnimationFromButtonIndex:buttonIndex];

  if (buttonIndex < _animations.count) {
    [_previewAnimations replaceObjectAtIndex:buttonIndex
                                  withObject:[self animationFromButtonIndex:buttonIndex]];
    [_animations replaceObjectAtIndex:buttonIndex withObject:previewAnimation];

  } else if (buttonIndex < [self numberOfPureAnimations]) {
    NSInteger index = buttonIndex - _animations.count;
    PHAnimation* animation = [self animationFromButtonIndex:buttonIndex];
    [_previewProcessingAnimations replaceObjectAtIndex:index withObject:animation];
    [_processingAnimations replaceObjectAtIndex:index withObject:previewAnimation];

  } else if (buttonIndex < [self numberOfPureAnimations] + _compositeAnimations.count) {
    NSInteger index = buttonIndex - [self numberOfPureAnimations];
    PHAnimation* animation = [self animationFromButtonIndex:buttonIndex];
    [_previewCompositeAnimations replaceObjectAtIndex:index withObject:animation];
    [_compositeAnimations replaceObjectAtIndex:index withObject:previewAnimation];

    if (_previewCompositeAnimationBeingEdited == previewAnimation) {
      _compositeAnimationBeingEdited = _compositeAnimations[index];
      _previewCompositeAnimationBeingEdited = _previewCompositeAnimations[index];
    }
  }
}

- (void)setActiveAnimationIndex:(NSInteger)buttonIndex {
  if (_previousAnimation == nil) {
    // Start the transition.
    _previousAnimation = _activeAnimation;
    _crossFadeStartTime = [NSDate timeIntervalSinceReferenceDate];

    NSInteger previousAnimationButtonIndex = [self buttonIndexOfAnimation:_previousAnimation];

    [self swapAnimationsAtButtonIndex:buttonIndex];

    _activeAnimation = [self animationFromButtonIndex:buttonIndex];
    _previewAnimation = [self previewAnimationFromButtonIndex:buttonIndex];

    if (_instantCrossfade) {
      [self commitTransitionAnimation];

    } else {
      [self refreshButtonColorAtIndex:buttonIndex];
      [self refreshButtonColorAtIndex:previousAnimationButtonIndex];
    }
  }
}

- (void)setPreviewAnimationIndex:(NSInteger)buttonIndex {
  PHAnimation* animation = [self animationFromButtonIndex:buttonIndex];
  if (animation == _activeAnimation) {
    // Switching to the active animation is redundant, so just set the preview
    // and bail out.
    _previewAnimation = animation;
    [self updateLaunchpad];
  }
  // Tapped the previewing animation again and we're not already on this animation.
  BOOL shouldChange = (_previewAnimation == animation);
  _previewAnimation = animation;
  if (shouldChange) {
    [self setActiveAnimationIndex:buttonIndex];
  } else {
    [self updateLaunchpad];
  }
}

- (void)setCompositeLayerAnimationIndex:(NSInteger)animationindex {
  if (animationindex == -1 || animationindex < [self numberOfPureAnimations]) {
    NSInteger currentAnimationIndex = [_previewCompositeAnimationBeingEdited indexOfAnimationForLayer:_activeCompositeLayer];
    if (currentAnimationIndex == animationindex) {
      // Tapping the current animation removes the animation from this layer.
      animationindex = -1;
    }
    [_compositeAnimationBeingEdited setAnimationIndex:animationindex forLayer:_activeCompositeLayer];
    [_previewCompositeAnimationBeingEdited setAnimationIndex:animationindex forLayer:_activeCompositeLayer];

  } else {
    _compositeAnimationBeingEdited = (PHCompositeAnimation *)[self animationFromButtonIndex:animationindex];
    _previewCompositeAnimationBeingEdited = (PHCompositeAnimation *)[self previewAnimationFromButtonIndex:animationindex];
    [self updateSideButtons];
  }
  [self updateGrid];
  [self updateTopButtons];
}

- (void)launchpadStateDidChange:(NSNotification *)notification {
  PHLaunchpadEvent event = [[notification.userInfo objectForKey:PHLaunchpadEventTypeUserInfoKey] intValue];
  NSInteger buttonIndex = [[notification.userInfo objectForKey:PHLaunchpadButtonIndexInfoKey] intValue];
  BOOL pressed = [[notification.userInfo objectForKey:PHLaunchpadButtonPressedUserInfoKey] boolValue];

  PHLaunchpadMIDIDriver* launchpad = PHApp().midiDriver;
  if (pressed && _isConfirmingDeletion && (event != PHLaunchpadEventRightButtonState || buttonIndex != PHLaunchpadSideButtonSendB)) {
    // When confirming the deletion, tapping any other button will cancel the
    // request for deletion.
    _isConfirmingDeletion = NO;
    [self refreshSideButtonColorAtIndex:PHLaunchpadSideButtonSendB];
    [launchpad flipBuffer];
    return;
  }

  switch (event) {
    case PHLaunchpadEventGridButtonState: {
      BOOL isValidButton = NO;
      if (buttonIndex < [self numberOfAnimations]) {
        PHAnimation* newAnimation = [self animationFromButtonIndex:buttonIndex];
        if (nil != newAnimation
            && (_launchpadMode == PHLaunchpadModeComposite
                || !newAnimation.isPipeAnimation)) {
          isValidButton = YES;
        }

        if (pressed && isValidButton) {
          if (_launchpadMode == PHLaunchpadModeAnimations) {
              [self setActiveAnimationIndex:buttonIndex];

          } else if (_launchpadMode == PHLaunchpadModePreview) {
            [self setPreviewAnimationIndex:buttonIndex];

          } else if (_launchpadMode == PHLaunchpadModeComposite) {
            [self setCompositeLayerAnimationIndex:buttonIndex];
          }
        }
      }

      if (!isValidButton) {
        [launchpad setButtonColor:pressed ? PHLaunchpadColorRedBright : PHLaunchpadColorOff
                    atButtonIndex:buttonIndex];
      }
      break;
    }

    case PHLaunchpadEventRightButtonState:
      if (pressed) {
        if (buttonIndex == PHLaunchpadSideButtonArm) {
          [self toggleLaunchpadMode:PHLaunchpadModePreview];

        } else if (buttonIndex == PHLaunchpadSideButtonTrackOn) {
          [self toggleLaunchpadMode:PHLaunchpadModeComposite];

        } else if (_launchpadMode == PHLaunchpadModeComposite) {
          if (buttonIndex == PHLaunchpadSideButtonSendA) {
            NSInteger indexOfObject = [_previewCompositeAnimations indexOfObject:_previewCompositeAnimationBeingEdited];
            if (indexOfObject == NSNotFound) {
              // Working on a new composite, save it to the list.
              [_compositeAnimations addObject:_compositeAnimationBeingEdited];
              [_previewCompositeAnimations addObject:_previewCompositeAnimationBeingEdited];

            } else {
              // Otherwise we want to create a new composite.
              _compositeAnimationBeingEdited = [PHCompositeAnimation animation];
              _compositeAnimationBeingEdited.driver = self.animationDriver;
              _previewCompositeAnimationBeingEdited = [PHCompositeAnimation animation];
              _previewCompositeAnimationBeingEdited.driver = self.animationDriver;
              [self updateTopButtons];
            }
            [self updateGrid];
            [self updateSideButtons];

          } else if (buttonIndex == PHLaunchpadSideButtonSendB) {
            // Delete/reset
            _isConfirmingDeletion = !_isConfirmingDeletion;
            if (!_isConfirmingDeletion) {
              // We've confirmed the deletion, reset the animation.
              [_compositeAnimationBeingEdited reset];
              [_previewCompositeAnimationBeingEdited reset];
              NSInteger indexOfObject = [_previewCompositeAnimations indexOfObject:_previewCompositeAnimationBeingEdited];
              if (indexOfObject != NSNotFound) {
                [_compositeAnimations removeObjectAtIndex:indexOfObject];
                [_previewCompositeAnimations removeObjectAtIndex:indexOfObject];
                if (_compositeAnimations.count > 0) {
                  // If there are any composite animations left, let's edit the one around where we just were.
                  indexOfObject = MIN(_compositeAnimations.count - 1, indexOfObject);
                  _compositeAnimationBeingEdited = _compositeAnimations[indexOfObject];
                  _previewCompositeAnimationBeingEdited = _previewCompositeAnimations[indexOfObject];
                }

                [self refreshButtonColorAtIndex:[self numberOfAnimations]];
              }
              [self updateLaunchpad];

            } else {
              [self refreshSideButtonColorAtIndex:(PHLaunchpadSideButton)buttonIndex];
            }
          }
        }
      }
      break;

    case PHLaunchpadEventTopButtonState:
      if (pressed) {
        if (_launchpadMode == PHLaunchpadModeComposite) {
          PHLaunchpadTopButton previousActiveLayer = _activeCompositeLayer;

          if (previousActiveLayer != buttonIndex) {
            _activeCompositeLayer = (PHLaunchpadTopButton)buttonIndex;
            [self refreshTopButtonColorAtIndex:(PHLaunchpadTopButton)previousActiveLayer];
            [self refreshTopButtonColorAtIndex:(PHLaunchpadTopButton)_activeCompositeLayer];

            [self updateGrid];
          } else {
            [self setCompositeLayerAnimationIndex:-1];
          }

        } else if (_launchpadMode == PHLaunchpadModeAnimations
                   || _launchpadMode == PHLaunchpadModePreview) {
          if (buttonIndex == PHLaunchpadTopButtonSession) {
            _instantCrossfade = !_instantCrossfade;
            if (nil != _previousAnimation) {
              [self commitTransitionAnimation];
            }
            [self refreshTopButtonColorAtIndex:(PHLaunchpadTopButton)buttonIndex];

          } else if (buttonIndex == PHLaunchpadTopButtonUser1) {
            _numberOfTimesUserButton1Pressed++;

          } else if (buttonIndex == PHLaunchpadTopButtonUser2) {
            _numberOfTimesUserButton2Pressed++;
          }
        }
      }

      if ((_launchpadMode == PHLaunchpadModeAnimations
           || _launchpadMode == PHLaunchpadModePreview)
          && (buttonIndex == PHLaunchpadTopButtonUser1
              || buttonIndex == PHLaunchpadTopButtonUser2
              || buttonIndex == PHLaunchpadTopButtonMixer)) {
        [launchpad setTopButtonColor:pressed ? PHLaunchpadColorGreenBright : PHLaunchpadColorOff
                             atIndex:buttonIndex];

        if (buttonIndex == PHLaunchpadTopButtonUser1) {
          _isUserButton1Pressed = pressed;

        } else if (buttonIndex == PHLaunchpadTopButtonUser2) {
          _isUserButton2Pressed = pressed;

        } else if (buttonIndex == PHLaunchpadTopButtonMixer) {
          _isMixerButtonPressed = pressed;
        }
      }

      if (_launchpadMode == PHLaunchpadModeAnimations
          || _launchpadMode == PHLaunchpadModePreview) {
        if (buttonIndex == PHLaunchpadTopButtonUpArrow) {
          if (pressed) {
            [self.animationDriver resetScales];
          }
          [launchpad setTopButtonColor:pressed ? PHLaunchpadColorRedBright : PHLaunchpadColorOff
                               atIndex:buttonIndex];
        }
      }
      break;
    default:
      break;
  }

  if (pressed) {
    [launchpad flipBuffer];
  }
}

- (PHAnimation *)previousAnimation {
  return _previousAnimation;
}

- (PHAnimation *)activeAnimation {
  return _activeAnimation;
}

- (PHAnimation *)activePreviewAnimation {
  if (_launchpadMode == PHLaunchpadModeComposite) {
    return _previewCompositeAnimationBeingEdited;
  }
  return _previewAnimation;
}

- (NSArray *)activeOverlays {
  return _activeOverlays;
}

#pragma mark - Display Link

- (void)commitTransitionAnimation {
  NSInteger previousAnimationButtonIndex = [self buttonIndexOfAnimation:_previousAnimation];
  NSInteger activeAnimationButtonIndex = [self buttonIndexOfAnimation:_activeAnimation];

  _previousAnimation = nil;

  [self refreshButtonColorAtIndex:previousAnimationButtonIndex];
  [self refreshButtonColorAtIndex:activeAnimationButtonIndex];
}

- (void)displayLinkDidFire:(NSNotification *)notification {
  if (nil != _previousAnimation) {
    NSTimeInterval delta = [NSDate timeIntervalSinceReferenceDate] - _crossFadeStartTime;
    if (delta >= kCrossFadeDuration) {
      [self commitTransitionAnimation];
    }
  }
}

#pragma mark - Processing Source Notifications

- (void)processingSourceListDidChange:(NSNotification *)notification {
  if ([NSThread currentThread] != [NSThread mainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self processingSourceListDidChange:notification];
    });
    return;
  }

  // Fucking shit tons of N^2 algorithms here because I'm too lazy to use a map.
  // We should never have more than a couple processing animations hooked up at
  // once so it shouldn't be a problem.

  // Add new animations.
  BOOL shouldUpdateLaunchpad = NO;
  NSArray* allSources = _processingServer.allSources;
  for (PHProcessingSource* source in allSources) {

    BOOL foundAnimation = NO;
    for (NSInteger ix = 0; ix < _processingAnimations.count; ++ix) {
      PHProcessingAnimation* animation = _processingAnimations[ix];
      if (animation.source == source) {
        foundAnimation = YES;
        break;
      }
    }

    if (!foundAnimation) {
      PHProcessingAnimation* animation = [PHProcessingAnimation animationWithSource:source];
      [_processingAnimations addObject:animation];
      PHProcessingAnimation* previewAnimation = [PHProcessingAnimation animationWithSource:source];
      [_previewProcessingAnimations addObject:previewAnimation];

      shouldUpdateLaunchpad = YES;
    }
  }

  // Remove old ones.
  NSArray* animations = [_processingAnimations copy];
  for (NSInteger ix = 0; ix < animations.count; ++ix ) {
    PHProcessingAnimation* animation = animations[ix];
    if (![allSources containsObject:animation.source]) {
      [_processingAnimations removeObjectAtIndex:ix];
      [_previewProcessingAnimations removeObjectAtIndex:ix];
      shouldUpdateLaunchpad = YES;

      [self refreshButtonColorAtIndex:[self numberOfAnimations]];
    }
  }
  if (shouldUpdateLaunchpad) {
    [self updateLaunchpad];
  }
}

#pragma mark - Floating Point Wall Context

- (CGContextRef)createWallContext {
  CGSize wallSize = CGSizeMake(kWallWidth, kWallHeight);

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  if (nil == colorSpace) {
    return nil;
  }
  CGContextRef wallContext =
  CGBitmapContextCreate(NULL,
                        wallSize.width,
                        wallSize.height,
                        32,
                        0,
                        colorSpace,
                        kCGImageAlphaPremultipliedLast
                        | kCGBitmapByteOrder32Host // Necessary for intel macs.
                        | kCGBitmapFloatComponents);
  CGColorSpaceRelease(colorSpace);
  if (nil == wallContext) {
    return nil;
  }
  return wallContext;
}

#pragma mark - Public Methods

- (CGContextRef)currentWallContext {
  CGSize wallSize = CGSizeMake(kWallWidth, kWallHeight);
  CGRect wallFrame = CGRectMake(0, 0, wallSize.width, wallSize.height);

  CGContextRef wallContext = [self createWallContext];
  CGContextClearRect(wallContext, wallFrame);

  PHAnimation* previousAnimation = [self previousAnimation];
  PHAnimation* activeAnimation = [self activeAnimation];
  if (nil != previousAnimation) {
    CGContextRef previousContext = [self createWallContext];
    CGContextRef activeContext = [self createWallContext];
    [previousAnimation bitmapWillStartRendering];
    [previousAnimation renderBitmapInContext:previousContext size:wallSize];
    [previousAnimation bitmapDidFinishRendering];

    [activeAnimation bitmapWillStartRendering];
    [activeAnimation renderBitmapInContext:activeContext size:wallSize];
    [activeAnimation bitmapDidFinishRendering];

    CGImageRef previousImage = CGBitmapContextCreateImage(previousContext);
    CGImageRef activeImage = CGBitmapContextCreateImage(activeContext);

    NSTimeInterval delta = [NSDate timeIntervalSinceReferenceDate] - _crossFadeStartTime;
    CGFloat t = PHEaseInEaseOut(MIN(1, delta / kCrossFadeDuration));

    CGContextSaveGState(wallContext);
    CGContextSetAlpha(wallContext, 1 - t);
    CGContextDrawImage(wallContext, wallFrame, previousImage);
    CGContextSetAlpha(wallContext, t);
    CGContextDrawImage(wallContext, wallFrame, activeImage);
    CGContextRestoreGState(wallContext);

    CGImageRelease(previousImage);
    CGImageRelease(activeImage);
    CGContextRelease(previousContext);
    CGContextRelease(activeContext);

  } else {
    [activeAnimation bitmapWillStartRendering];
    [activeAnimation renderBitmapInContext:wallContext size:wallSize];
    [activeAnimation bitmapDidFinishRendering];
  }

  if (_isMixerButtonPressed) {
    CGImageRef imageRef = [_pixelHeartTextSpritesheet imageAtX:0 y:0];
    CGSize textSize = _pixelHeartTextSpritesheet.spriteSize;
    CGContextDrawImage(wallContext, CGRectMake(floorf((wallSize.width - textSize.width) / 2),
                                               floorf((wallSize.height - textSize.height) / 2),
                                               textSize.width, textSize.height), imageRef);
    CGImageRelease(imageRef);
  }

  [self drawOverlaysInContext:wallContext];
  
  return wallContext;
}

- (CGContextRef)previewWallContext {
  CGSize wallSize = CGSizeMake(kWallWidth, kWallHeight);
  CGRect wallFrame = CGRectMake(0, 0, wallSize.width, wallSize.height);

  CGContextRef wallContext = [self createWallContext];
  CGContextClearRect(wallContext, wallFrame);

  PHAnimation* activeAnimation = [self activePreviewAnimation];
  [activeAnimation bitmapWillStartRendering];
  [activeAnimation renderBitmapInContext:wallContext size:wallSize];
  [activeAnimation bitmapDidFinishRendering];

  if (_isMixerButtonPressed) {
    CGImageRef imageRef = [_pixelHeartTextSpritesheet imageAtX:0 y:0];
    CGSize textSize = _pixelHeartTextSpritesheet.spriteSize;
    CGContextDrawImage(wallContext, CGRectMake(floorf((wallSize.width - textSize.width) / 2),
                                               floorf((wallSize.height - textSize.height) / 2),
                                               textSize.width, textSize.height), imageRef);
    CGImageRelease(imageRef);
  }

  [self drawOverlaysInContext:wallContext];
  
  return wallContext;
}

- (NSArray *)allMotes {
  return _moteServer.allMotes;
}

- (void)addOverlay:(PHOverlay *)overlay {
  @synchronized(_activeOverlays) {
    [_activeOverlays addObject:overlay];
  }
}

- (void)removeOverlay:(PHOverlay *)overlay {
  @synchronized(_activeOverlays) {
    [_activeOverlays removeObject:overlay];
  }
}

- (void)drawOverlaysInContext:(CGContextRef)cx
{
  NSArray *overlays = nil;
  @synchronized(_activeOverlays) {
   overlays = [NSArray arrayWithArray:_activeOverlays];
  }

  CGSize wallSize = CGSizeMake(kWallWidth, kWallHeight);
  for (PHOverlay *overlay in overlays) {
    [overlay bitmapWillStartRendering];
    [overlay renderBitmapInContext:cx size:wallSize];
    [overlay bitmapDidFinishRendering];
  }
}

- (void)didTick {
  _numberOfTimesUserButton1Pressed = 0;
  _numberOfTimesUserButton2Pressed = 1;
  [_moteServer didTick];
}

- (void)pointTooltipAtView:(NSView *)view withString:(NSString *)string {
  if (string.length == 0) {
    [self hideTooltip];
    return;
  }

  _showingTooltip = YES;
  [self.tooltipWindow setTooltip:string];

  CGRect frame = self.tooltipWindow.frame;
  CGRect windowFrame = [view convertRect:view.bounds toView:nil];
  CGRect screenFrame = [view.window convertRectToScreen:windowFrame];
  frame.origin.x = screenFrame.origin.x - frame.size.width;
  frame.origin.y = screenFrame.origin.y + frame.size.height;

  [self.tooltipWindow setFrame:frame display:YES];
  [self bringTooltipForward];
}

- (void)bringTooltipForward {
  if (_showingTooltip) {
    [self.tooltipWindow makeKeyAndOrderFront:self];
  }
}

- (void)hideTooltip {
  _showingTooltip = NO;
  [self.tooltipWindow orderOut:self];
}

- (NSString *)tooltipForButtonIndex:(NSInteger)buttonIndex {
  if (buttonIndex < _animations.count) {
    PHAnimation* animation = [_animations objectAtIndex:buttonIndex];
    return animation.tooltipName;

  } else if (buttonIndex < [self numberOfPureAnimations]) {
    PHAnimation* animation = [_processingAnimations objectAtIndex:buttonIndex - _animations.count];
    return animation.tooltipName;

  } else if (buttonIndex < [self numberOfAnimations]) {
    PHCompositeAnimation* compositeAnimation = [_compositeAnimations objectAtIndex:
                                                buttonIndex - [self numberOfPureAnimations]];

    NSMutableString* tooltip = [NSMutableString string];
    for (PHLaunchpadTopButton ix = 0; ix < PHLaunchpadTopButtonCount; ++ix) {
      NSInteger animationIndex = [compositeAnimation indexOfAnimationForLayer:ix];
      if (animationIndex >= 0 && animationIndex < [self numberOfPureAnimations]) {
        if (tooltip.length > 0) {
          [tooltip appendString:@"\n"];
        }
        PHAnimation* animation = [self animationFromButtonIndex:animationIndex];
        [tooltip appendString:animation.tooltipName];
      }
    }
    return tooltip;
  }
  return nil;
}

- (NSString *)tooltipForTopButtonIndex:(NSInteger)buttonIndex {
  if (_launchpadMode == PHLaunchpadModeAnimations
      || _launchpadMode == PHLaunchpadModePreview) {
    if (buttonIndex == PHLaunchpadTopButtonUpArrow) {
      return @"Reset Audio Scalers";
    } else if (buttonIndex == PHLaunchpadTopButtonSession) {
      return @"Toggle Instant Transitions";
    }
  } else if (_launchpadMode == PHLaunchpadModeComposite) {
    NSInteger animationIndex = [_compositeAnimationBeingEdited indexOfAnimationForLayer:(PHLaunchpadTopButton)buttonIndex];
    NSString* string = [NSString stringWithFormat:@"Composite Layer %ld", buttonIndex + 1];
    if (animationIndex >= 0 && animationIndex < [self numberOfPureAnimations]) {
      PHAnimation* animation = [_animations objectAtIndex:animationIndex];
      string = [string stringByAppendingFormat:@"\n%@", animation.tooltipName];
    }
    return string;
  }
  return nil;
}

- (NSString *)tooltipForSideButtonIndex:(NSInteger)buttonIndex {
  if (buttonIndex == PHLaunchpadSideButtonArm) {
    return @"Toggle Preview Mode";
  } else if (buttonIndex == PHLaunchpadSideButtonTrackOn) {
    return @"Toggle Composite Mode";
  } else if (_launchpadMode == PHLaunchpadModeComposite) {
    if (buttonIndex == PHLaunchpadSideButtonSendA) {
      BOOL editingExistingComposite = [self buttonIndexOfAnimation:_previewCompositeAnimationBeingEdited] >= 0;
      return editingExistingComposite ? @"Create New Composite" : @"Save Composite";
    } else if (buttonIndex == PHLaunchpadSideButtonSendB) {
      return @"Delete composite";
    }
  }
  return nil;
}

@end
