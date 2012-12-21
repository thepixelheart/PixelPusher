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

#import "PHWallView.h"

#import "AppDelegate.h"
#import "PHBitmapPipeline.h"
#import "PHDisplayLink.h"
#import "PHDriver.h"
#import "PHFMODRecorder.h"
#import "PHLaunchpadMIDIDriver.h"
#import "PHQuartzRenderer.h"
#import "Utilities.h"

// Animations
#import "PHAnimation.h"
#import "PHBasicSpectrumAnimation.h"
#import "PHBouncingCircleAnimation.h"
#import "PHBassPlate.h"

const NSInteger kPixelBorderSize = 1;
const NSInteger kPixelSize = 8;

static const NSTimeInterval kCrossFadeDuration = 1;

typedef enum {
  PHLaunchpadModeAnimations,
  PHLaunchpadModeTest,
} PHLaunchpadMode;

@implementation PHWallView {
  PHQuartzRenderer *_renderer;
  NSDate* _firstTick;
  PHAnimationDriver* _driver;

  NSArray* _animations;
  NSInteger _activeAnimation;
  PHLaunchpadMode _launchpadMode;

  NSInteger _previousAnimation;
  NSTimeInterval _crossFadeStartTime;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
  [super awakeFromNib];

  _launchpadMode = PHLaunchpadModeAnimations;

  _animations = @[
    [PHBasicSpectrumAnimation animation],
    [PHBassPlate animation],
    [PHBouncingCircleAnimation animation],
  ];
  _activeAnimation = 0;
  _previousAnimation = -1;

  [self updateLaunchpad];

  _driver = [[PHAnimationDriver alloc] init];

  for (PHAnimation* animation in _animations) {
    animation.driver = _driver;
  }

  NSString* filename = @"PixelDriver.app/Contents/Resources/clouds.qtz";
  _renderer = [[PHQuartzRenderer alloc] initWithCompositionPath:filename
                                                     pixelsWide:kWallWidth
                                                     pixelsHigh:kWallHeight];

  [self driverConnectionDidChange];

  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(driverConnectionDidChange)
             name:PHDriverConnectionStateDidChangeNotification
           object:nil];
  [nc addObserver:self
         selector:@selector(launchpadStateDidChange:)
             name:PHLaunchpadDidReceiveStateChangeNotification
           object:nil];
  [nc addObserver:self
         selector:@selector(launchpadDidConnect:)
             name:PHLaunchpadDidConnectNotification
           object:nil];

  _firstTick = [NSDate date];
}

- (void)animationLaunchpadMode {
  PHLaunchpadMIDIDriver* launchpad = PHApp().midiDriver;

  for (NSInteger ix = 0; ix < _animations.count; ++ix) {
    BOOL isActive = _activeAnimation == ix;
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
        if (_previousAnimation == -1) {
          _previousAnimation = _activeAnimation;
          _crossFadeStartTime = [NSDate timeIntervalSinceReferenceDate];
          _activeAnimation = buttonIndex;

          [launchpad setButtonColor:PHLaunchpadColorGreenFlashing atButtonIndex:_previousAnimation];
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

- (void)displayLinkDidFire:(NSNotification *)notification {
  [super displayLinkDidFire:notification];

  if (_previousAnimation >= 0) {
    NSTimeInterval delta = [NSDate timeIntervalSinceReferenceDate] - _crossFadeStartTime;
    if (delta >= kCrossFadeDuration) {
      PHLaunchpadMIDIDriver* launchpad = PHApp().midiDriver;
      [launchpad setButtonColor:PHLaunchpadColorGreenDim atButtonIndex:_previousAnimation];
      [launchpad setButtonColor:PHLaunchpadColorGreenBright atButtonIndex:_activeAnimation];

      _previousAnimation = -1;
    }
  }
}

#pragma mark - Rendering

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

- (void)renderBitmapInContext:(CGContextRef)cx
                         size:(CGSize)size
                     spectrum:(float *)spectrum
       numberOfSpectrumValues:(NSInteger)numberOfSpectrumValues {
  CGSize wallSize = CGSizeMake(kWallWidth, kWallHeight);
  CGRect wallFrame = CGRectMake(0, 0, wallSize.width, wallSize.height);

  CGContextRef wallContext = [self createWallContext];
  if (nil == wallContext) {
    return;
  }

  [_driver setSpectrum:spectrum numberOfValues:numberOfSpectrumValues];

  CGContextClearRect(wallContext, CGRectMake(0, 0, wallSize.width, wallSize.height));

  if (_previousAnimation >= 0) {
    CGContextRef previousContext = [self createWallContext];
    CGContextRef activeContext = [self createWallContext];
    PHAnimation* previous = [_animations objectAtIndex:_previousAnimation];
    [previous renderBitmapInContext:previousContext size:wallSize];
    PHAnimation* active = [_animations objectAtIndex:_activeAnimation];
    [active renderBitmapInContext:activeContext size:wallSize];

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
    PHAnimation* animation = [_animations objectAtIndex:_activeAnimation];
    [animation renderBitmapInContext:wallContext size:wallSize];
  }

  [PHApp().driver queueContext:wallContext];

  [[NSColor blackColor] set];
  CGRect bounds = CGRectMake(0, 0, size.width, size.height);
  CGContextFillRect(cx, bounds);

  if (PHApp().driver.isConnected) {
    [[NSColor colorWithDeviceRed:32.f / 255.f green:32.f / 255.f blue:32.f / 255.f alpha:1] set];
  } else {
    [[NSColor colorWithDeviceRed:64.f / 255.f green:32.f / 255.f blue:32.f / 255.f alpha:1] set];
  }
  CGRect frame = CGRectMake(0, 0, kPixelBorderSize, size.height);
  for (NSInteger ix = 0; ix <= kWallWidth; ++ix) {
    frame.origin.x = ix * (kPixelBorderSize + kPixelSize);
    CGContextFillRect(cx, frame);
  }
  frame = CGRectMake(0, 0, size.width, kPixelBorderSize);
  for (NSInteger iy = 0; iy <= kWallHeight; ++iy) {
    frame.origin.y = iy * (kPixelBorderSize + kPixelSize);
    CGContextFillRect(cx, frame);
  }

  float* data = (float *)CGBitmapContextGetData(wallContext);
  size_t bytesPerRow = CGBitmapContextGetBytesPerRow(wallContext);

  NSRect pixelFrame = NSMakeRect(0, 0, 1, 1);
  NSRect viewFrame = NSMakeRect(0, 0, kPixelSize, kPixelSize);
  for (NSInteger iy = 0; iy < kWallHeight; ++iy) {
    pixelFrame.origin.y = iy;
    viewFrame.origin.y = (iy + 1) * kPixelBorderSize + iy * kPixelSize;

    for (NSInteger ix = 0; ix < kWallWidth; ++ix) {
      pixelFrame.origin.x = ix;
      viewFrame.origin.x = (ix + 1) * kPixelBorderSize + ix * kPixelSize;

      NSInteger offset = ix * 4 + iy * (bytesPerRow / 4);
      CGContextSetRGBFillColor(cx, data[offset] / data[offset + 3], data[offset + 1] / data[offset + 3], data[offset + 2] / data[offset + 3], data[offset + 3]);
      CGContextFillRect(cx, viewFrame);
    }
  }

  CGContextRelease(wallContext);
}

#pragma mark - Driver Notifications

- (void)driverConnectionDidChange {
  if (PHApp().driver.isConnected) {
    NSLog(@"Driver is attached");
  } else {
    NSLog(@"Driver is detached");
  }
}

@end
