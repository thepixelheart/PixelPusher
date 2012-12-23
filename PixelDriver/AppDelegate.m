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
#import "PHDisplayLink.h"
#import "PHDriver.h"
#import "PHFMODRecorder.h"
#import "PHLaunchpadMIDIDriver.h"
#import "PHUSBNotifier.h"
#import "PHWallView.h"

static const NSTimeInterval kCrossFadeDuration = 1;

typedef enum {
  PHLaunchpadModeAnimations,
  PHLaunchpadModePreview,
  PHLaunchpadModeComposite,
} PHLaunchpadMode;

AppDelegate *PHApp() {
  return (AppDelegate *)[NSApplication sharedApplication].delegate;
}

@interface PHCompositeAnimation : PHAnimation
@end

@implementation PHCompositeAnimation

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {

}

@end

@implementation AppDelegate {
  PHDisplayLink* _displayLink;
  PHUSBNotifier* _usbNotifier;

  NSMutableArray* _animations;
  NSMutableArray* _previewAnimations;
  NSMutableArray* _compositeAnimations;

  PHLaunchpadMode _launchpadMode;

  // Animation/preview top button modes
  BOOL _instantCrossfade;

  // Composite mode
  PHLaunchpadTopButton _activeCompositeLayer;

  NSInteger _activeAnimationIndex;
  NSInteger _previousAnimationIndex;
  NSInteger _previewAnimationIndex;
  NSTimeInterval _crossFadeStartTime;
}

@synthesize audioRecorder = _audioRecorder;
@synthesize midiDriver = _midiDriver;

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
    animation.driver = _animationDriver;
  }

  return [animations mutableCopy];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
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

  self.window.wallView.pixelSize = 16;
  [self prepareWindow:self.window];
  self.previewWindow.wallView.pixelSize = 8;
  [self prepareWindow:self.previewWindow];

  [self.launchpadWindow setAcceptsMouseMovedEvents:YES];
  [self.launchpadWindow setMovableByWindowBackground:YES];

  self.window.wallView.primary = YES;

  _driver = [[PHDriver alloc] init];
  _displayLink = [[PHDisplayLink alloc] init];
  _usbNotifier = [[PHUSBNotifier alloc] init];
  [self midiDriver];

  _launchpadMode = PHLaunchpadModeAnimations;

  _animationDriver = [[PHAnimationDriver alloc] init];
  _animations = [self createAnimations];
  _previewAnimations = [self createAnimations];
  _activeAnimationIndex = 6;
  _previewAnimationIndex = 1;
  _previousAnimationIndex = -1;
  _activeCompositeLayer = 0;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [self.window performSelector:@selector(makeKeyAndOrderFront:) withObject:self afterDelay:0.5];
  [self.previewWindow performSelector:@selector(makeKeyAndOrderFront:) withObject:self afterDelay:0.5];
  [self.launchpadWindow performSelector:@selector(makeKeyAndOrderFront:) withObject:self afterDelay:0.5];
  [self.window center];

  [self launchpadDidConnect:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
  return YES;
}

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

- (PHLaunchpadColor)buttonColorForButtonIndex:(NSInteger)buttonIndex {
  if (buttonIndex >= _animations.count) {
    return PHLaunchpadColorOff;
  }

  if (_launchpadMode == PHLaunchpadModeAnimations) {
    BOOL isActive = _activeAnimationIndex == buttonIndex;
    return isActive ? PHLaunchpadColorGreenBright : PHLaunchpadColorGreenDim;

  } else if (_launchpadMode == PHLaunchpadModePreview) {
    BOOL isActive = _activeAnimationIndex == buttonIndex;
    BOOL isPreview = _previewAnimationIndex == buttonIndex;
    return (isActive
            ? (isPreview
               ? PHLaunchpadColorRedBright
               : PHLaunchpadColorGreenBright)
            : (isPreview
               ? PHLaunchpadColorYellowBright
               : PHLaunchpadColorAmberDim));
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
    return (_activeCompositeLayer == buttonIndex) ? PHLaunchpadColorAmberBright : PHLaunchpadColorAmberDim;

  } else {
    return PHLaunchpadColorOff;
  }
}

- (PHLaunchpadColor)sideButtonColorForIndex:(PHLaunchpadSideButton)buttonIndex {
  if (buttonIndex == PHLaunchpadSideButtonArm) {
    return (_launchpadMode == PHLaunchpadModePreview) ? PHLaunchpadColorGreenBright : PHLaunchpadColorAmberDim;

  } else if (buttonIndex == PHLaunchpadSideButtonTrackOn) {
    return (_launchpadMode == PHLaunchpadModeComposite) ? PHLaunchpadColorGreenBright : PHLaunchpadColorAmberDim;

  } else {
    return PHLaunchpadColorOff;
  }
}

- (void)commitTransitionAnimation {
  PHLaunchpadMIDIDriver* launchpad = PHApp().midiDriver;
  [launchpad setButtonColor:[self buttonColorForButtonIndex:_previousAnimationIndex] atButtonIndex:_previousAnimationIndex];
  [launchpad setButtonColor:[self buttonColorForButtonIndex:_activeAnimationIndex] atButtonIndex:_activeAnimationIndex];

  _previousAnimationIndex = -1;
}

- (void)displayLinkDidFire:(NSNotification *)notification {
  float* spectrum = [notification.userInfo[PHDisplayLinkFiredSpectrumKey] pointerValue];
  NSInteger numberOfSpectrumValues = [notification.userInfo[PHDisplayLinkFiredNumberOfSpectrumValuesKey] longValue];
  [_animationDriver setSpectrum:spectrum numberOfValues:numberOfSpectrumValues];

  if (_previousAnimationIndex >= 0) {
    NSTimeInterval delta = [NSDate timeIntervalSinceReferenceDate] - _crossFadeStartTime;
    if (delta >= kCrossFadeDuration) {
      [self commitTransitionAnimation];
    }
  }
}

#pragma mark - Launchpad

- (void)updateLaunchpad {
  PHLaunchpadMIDIDriver* launchpad = PHApp().midiDriver;

  for (NSInteger ix = 0; ix < _animations.count; ++ix) {
    [launchpad setButtonColor:[self buttonColorForButtonIndex:ix]
                atButtonIndex:ix];
  }
  for (NSInteger ix = 0; ix < PHLaunchpadTopButtonCount; ++ix) {
    [launchpad setTopButtonColor:[self topButtonColorForIndex:(PHLaunchpadTopButton)ix]
                         atIndex:ix];
  }
  for (NSInteger ix = 0; ix < PHLaunchpadSideButtonCount; ++ix) {
    [launchpad setRightButtonColor:[self sideButtonColorForIndex:(PHLaunchpadSideButton)ix]
                           atIndex:ix];
  }
}

- (void)toggleLaunchpadMode:(PHLaunchpadMode)mode {
  if (_launchpadMode == mode) {
    _launchpadMode = PHLaunchpadModeAnimations;
  } else {
    _launchpadMode = mode;
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

- (void)setActiveAnimationIndex:(NSInteger)animationIndex {
  if (_previousAnimationIndex == -1) {
    _previousAnimationIndex = _activeAnimationIndex;
    _crossFadeStartTime = [NSDate timeIntervalSinceReferenceDate];
    _activeAnimationIndex = animationIndex;
    _previewAnimationIndex = animationIndex;

    PHAnimation* animation = [_previewAnimations objectAtIndex:_activeAnimationIndex];
    [_previewAnimations replaceObjectAtIndex:_activeAnimationIndex withObject:[_animations objectAtIndex:_activeAnimationIndex]];
    [_animations replaceObjectAtIndex:_activeAnimationIndex withObject:animation];

    if (_instantCrossfade) {
      [self commitTransitionAnimation];
    } else {
      PHLaunchpadMIDIDriver* launchpad = PHApp().midiDriver;
      [launchpad setButtonColor:((_launchpadMode == PHLaunchpadModeAnimations)
                                 ? PHLaunchpadColorAmberDim
                                 : PHLaunchpadColorRedDim)
                  atButtonIndex:_activeAnimationIndex];
      [launchpad setButtonColor:PHLaunchpadColorGreenFlashing atButtonIndex:_previousAnimationIndex];
    }
  }
}

- (void)setPreviewAnimationIndex:(NSInteger)animationIndex {
  if (animationIndex == _activeAnimationIndex) {
    _previewAnimationIndex = animationIndex;
    [self updateLaunchpad];
    return;
  }
  BOOL shouldChange = _previewAnimationIndex == animationIndex;
  _previewAnimationIndex = animationIndex;
  if (shouldChange) {
    [self setActiveAnimationIndex:animationIndex];
  } else {
    [self updateLaunchpad];
  }
}

- (void)launchpadStateDidChange:(NSNotification *)notification {
  PHLaunchpadEvent event = [[notification.userInfo objectForKey:PHLaunchpadEventTypeUserInfoKey] intValue];
  NSInteger buttonIndex = [[notification.userInfo objectForKey:PHLaunchpadButtonIndexInfoKey] intValue];
  BOOL pressed = [[notification.userInfo objectForKey:PHLaunchpadButtonPressedUserInfoKey] boolValue];

  PHLaunchpadMIDIDriver* launchpad = PHApp().midiDriver;
  switch (event) {
    case PHLaunchpadEventGridButtonState:
      if (pressed && buttonIndex < _animations.count) {
        if (_launchpadMode == PHLaunchpadModeAnimations) {
          [self setActiveAnimationIndex:buttonIndex];
        } else if (_launchpadMode == PHLaunchpadModePreview) {
          [self setPreviewAnimationIndex:buttonIndex];
        }

      } else if (buttonIndex >= _animations.count) {
        [launchpad setButtonColor:pressed ? PHLaunchpadColorRedBright : PHLaunchpadColorOff atButtonIndex:buttonIndex];
      }
      break;

    case PHLaunchpadEventRightButtonState:
      if (pressed) {
        if (buttonIndex == PHLaunchpadSideButtonArm) {
          [self toggleLaunchpadMode:PHLaunchpadModePreview];
        } else if (buttonIndex == PHLaunchpadSideButtonTrackOn) {
          [self toggleLaunchpadMode:PHLaunchpadModeComposite];
        }
      }
      break;

    case PHLaunchpadEventTopButtonState:
      if (pressed) {
        if (_launchpadMode == PHLaunchpadModeComposite) {
          PHLaunchpadTopButton previousActiveLayer = _activeCompositeLayer;
          if (previousActiveLayer != buttonIndex) {
            _activeCompositeLayer = (PHLaunchpadTopButton)buttonIndex;
            [launchpad setTopButtonColor:[self topButtonColorForIndex:(PHLaunchpadTopButton)previousActiveLayer]
                                 atIndex:previousActiveLayer];
            [launchpad setTopButtonColor:[self topButtonColorForIndex:(PHLaunchpadTopButton)_activeCompositeLayer]
                                 atIndex:_activeCompositeLayer];
        }

        } else if (buttonIndex == PHLaunchpadTopButtonSession
            && (_launchpadMode == PHLaunchpadModeAnimations
                || _launchpadMode == PHLaunchpadModePreview)) {
          _instantCrossfade = !_instantCrossfade;
          if (_previousAnimationIndex >= 0) {
            [self commitTransitionAnimation];
          }
          [launchpad setTopButtonColor:_instantCrossfade ? PHLaunchpadColorGreenBright : PHLaunchpadColorOff
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
  if (_previousAnimationIndex >= 0 && _previousAnimationIndex < _animations.count) {
    return [_animations objectAtIndex:_previousAnimationIndex];
  } else {
    return nil;
  }
}

- (PHAnimation *)activeAnimation {
  if (_activeAnimationIndex >= 0 && _activeAnimationIndex < _animations.count) {
    return [_animations objectAtIndex:_activeAnimationIndex];
  } else {
    return nil;
  }
}

- (PHAnimation *)activePreviewAnimation {
  if (_previewAnimationIndex >= 0 && _previewAnimationIndex < _animations.count) {
    return [_previewAnimations objectAtIndex:_previewAnimationIndex];
  } else {
    return nil;
  }
}

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

- (NSTimeInterval)easeInEaseOut:(NSTimeInterval)t {
  t *= 2.0f;
  if (t < 1) {
    return 0.5f * t * t;
  }
  t--;
  return -0.5f * (t * (t - 2.0f) - 1.0f);
}

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
    [previousAnimation renderBitmapInContext:previousContext size:wallSize];
    [activeAnimation renderBitmapInContext:activeContext size:wallSize];

    CGImageRef previousImage = CGBitmapContextCreateImage(previousContext);
    CGImageRef activeImage = CGBitmapContextCreateImage(activeContext);

    NSTimeInterval delta = [NSDate timeIntervalSinceReferenceDate] - _crossFadeStartTime;
    CGFloat t = [self easeInEaseOut:MIN(1, delta / kCrossFadeDuration)];

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
    [activeAnimation renderBitmapInContext:wallContext size:wallSize];
  }

  return wallContext;
}

- (CGContextRef)previewWallContext {
  CGSize wallSize = CGSizeMake(kWallWidth, kWallHeight);
  CGRect wallFrame = CGRectMake(0, 0, wallSize.width, wallSize.height);

  CGContextRef wallContext = [self createWallContext];
  CGContextClearRect(wallContext, wallFrame);

  PHAnimation* activeAnimation = [self activePreviewAnimation];
  [activeAnimation renderBitmapInContext:wallContext size:wallSize];

  return wallContext;
}

@end
