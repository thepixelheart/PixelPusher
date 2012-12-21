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

#import "PHDisplayLink.h"
#import "PHDriver.h"
#import "PHFMODRecorder.h"
#import "PHLaunchpadMIDIDriver.h"
#import "PHUSBNotifier.h"
#import "PHWallView.h"

#import "PHBasicSpectrumAnimation.h"
#import "PHBouncingCircleAnimation.h"
#import "PHBassPlate.h"

static const NSTimeInterval kCrossFadeDuration = 1;

typedef enum {
  PHLaunchpadModeAnimations,
  PHLaunchpadModeTest,
} PHLaunchpadMode;

AppDelegate *PHApp() {
  return (AppDelegate *)[NSApplication sharedApplication].delegate;
}

@implementation AppDelegate {
  PHDisplayLink* _displayLink;
  PHUSBNotifier* _usbNotifier;

  NSArray* _animations;
  NSArray* _previewAnimations;
  NSInteger _activeAnimationIndex;
  PHLaunchpadMode _launchpadMode;

  NSInteger _previousAnimationIndex;
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

- (NSArray *)createAnimations {
  NSArray* animations = @[
  [PHBasicSpectrumAnimation animation],
  [PHBassPlate animation],
  [PHBouncingCircleAnimation animation],
  ];

  for (PHAnimation* animation in animations) {
    animation.driver = _animationDriver;
  }

  return animations;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
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

  self.window.wallView.primary = YES;

  _driver = [[PHDriver alloc] init];
  _displayLink = [[PHDisplayLink alloc] init];
  _usbNotifier = [[PHUSBNotifier alloc] init];
  [self midiDriver];

  _launchpadMode = PHLaunchpadModeAnimations;

  _animationDriver = [[PHAnimationDriver alloc] init];
  _animations = [self createAnimations];
  _previewAnimations = [self createAnimations];
  _activeAnimationIndex = 0;
  _previousAnimationIndex = -1;

  [self updateLaunchpad];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [self.window performSelector:@selector(makeKeyAndOrderFront:) withObject:self afterDelay:0.5];
  [self.window center];
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

- (void)displayLinkDidFire:(NSNotification *)notification {
  float* spectrum = [notification.userInfo[PHDisplayLinkFiredSpectrumKey] pointerValue];
  NSInteger numberOfSpectrumValues = [notification.userInfo[PHDisplayLinkFiredNumberOfSpectrumValuesKey] longValue];
  [_animationDriver setSpectrum:spectrum numberOfValues:numberOfSpectrumValues];

  if (_previousAnimationIndex >= 0) {
    NSTimeInterval delta = [NSDate timeIntervalSinceReferenceDate] - _crossFadeStartTime;
    if (delta >= kCrossFadeDuration) {
      PHLaunchpadMIDIDriver* launchpad = PHApp().midiDriver;
      [launchpad setButtonColor:PHLaunchpadColorGreenDim atButtonIndex:_previousAnimationIndex];
      [launchpad setButtonColor:PHLaunchpadColorGreenBright atButtonIndex:_activeAnimationIndex];

      _previousAnimationIndex = -1;
    }
  }
}

#pragma mark - Launchpad

- (void)animationLaunchpadMode {
  PHLaunchpadMIDIDriver* launchpad = PHApp().midiDriver;

  for (NSInteger ix = 0; ix < _animations.count; ++ix) {
    BOOL isActive = _activeAnimationIndex == ix;
    [launchpad setButtonColor:isActive ? PHLaunchpadColorGreenBright : PHLaunchpadColorGreenDim
                atButtonIndex:ix];
  }
}

- (void)testLaunchpadMode {
  PHLaunchpadMIDIDriver* launchpad = PHApp().midiDriver;

  [launchpad setRightButtonColor:PHLaunchpadColorGreenBright atIndex:PHLaunchpadSideButtonArm];
}

- (void)updateLaunchpad {
  PHLaunchpadMIDIDriver* launchpad = PHApp().midiDriver;
  [launchpad reset];

  if (_launchpadMode != PHLaunchpadModeTest) {
    [launchpad setRightButtonColor:PHLaunchpadColorAmberDim atIndex:PHLaunchpadSideButtonArm];
  }

  switch (_launchpadMode) {
    case PHLaunchpadModeAnimations: {
      [self animationLaunchpadMode];
      break;
    }
    case PHLaunchpadModeTest: {
      [self testLaunchpadMode];
      break;
    }
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
  [self updateLaunchpad];
}

- (void)launchpadStateDidChange:(NSNotification *)notification {
  PHLaunchpadEvent event = [[notification.userInfo objectForKey:PHLaunchpadEventTypeUserInfoKey] intValue];
  NSInteger buttonIndex = [[notification.userInfo objectForKey:PHLaunchpadButtonIndexInfoKey] intValue];
  BOOL pressed = [[notification.userInfo objectForKey:PHLaunchpadButtonPressedUserInfoKey] boolValue];

  PHLaunchpadMIDIDriver* launchpad = PHApp().midiDriver;
  switch (event) {
    case PHLaunchpadEventGridButtonState:
      if (pressed && buttonIndex < _animations.count) {
        if (_previousAnimationIndex == -1) {
          _previousAnimationIndex = _activeAnimationIndex;
          _crossFadeStartTime = [NSDate timeIntervalSinceReferenceDate];
          _activeAnimationIndex = buttonIndex;

          [launchpad setButtonColor:PHLaunchpadColorGreenFlashing atButtonIndex:_previousAnimationIndex];
        }

      } else if (buttonIndex >= _animations.count) {
        [launchpad setButtonColor:pressed ? PHLaunchpadColorRedBright : PHLaunchpadColorOff atButtonIndex:buttonIndex];
      }
      break;
    case PHLaunchpadEventRightButtonState:
      if (pressed && buttonIndex == PHLaunchpadSideButtonArm) {
        [self toggleLaunchpadMode:PHLaunchpadModeTest];
      }
      break;
    default:
      break;
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
  if (_activeAnimationIndex >= 0 && _activeAnimationIndex < _animations.count) {
    return [_previewAnimations objectAtIndex:_activeAnimationIndex];
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
