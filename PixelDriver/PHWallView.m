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
#import "PHBouncingCircleAnimation.h"
#import "PHBassPlate.h"

const NSInteger kPixelBorderSize = 1;
const NSInteger kPixelSize = 8;

@implementation PHWallView {
  PHQuartzRenderer *_renderer;
  NSDate* _firstTick;
  PHAnimation* _animation;
  PHAnimationDriver* _driver;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
  [super awakeFromNib];

  _animation = [[PHBassPlate alloc] init];
  _driver = [[PHAnimationDriver alloc] init];

  NSString* filename = @"PixelDriver.app/Contents/Resources/clouds.qtz";
  _renderer = [[PHQuartzRenderer alloc] initWithCompositionPath:filename
                                                     pixelsWide:kWallWidth
                                                     pixelsHigh:kWallHeight];

  [self driverConnectionDidChange];

  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(driverConnectionDidChange)
             name:PHDriverConnectionStateDidChangeNotification
           object:nil];

  _firstTick = [NSDate date];


  [nc addObserver:self
         selector:@selector(launchpadStateDidChange:)
             name:PHLaunchpadDidReceiveStateChangeNotification
           object:nil];
}

- (void)launchpadStateDidChange:(NSNotification *)notification {
  PHLaunchpadEvent event = [[notification.userInfo objectForKey:PHLaunchpadEventTypeUserInfoKey] intValue];
  NSInteger buttonIndex = [[notification.userInfo objectForKey:PHLaunchpadButtonIndexInfoKey] intValue];
  BOOL pressed = [[notification.userInfo objectForKey:PHLaunchpadButtonPressedUserInfoKey] boolValue];

  switch (event) {
    case PHLaunchpadEventRightButtonState:
      if (buttonIndex == PHLaunchpadSideButtonArm) {
        PHLaunchpadMIDIDriver* midi = PHApp().midiDriver;
        if (pressed) {
          [midi reset];
        }
        [midi setRightButtonColor:pressed ? PHLaunchpadColorGreenBright : PHLaunchpadColorOff atIndex:buttonIndex];
        for (NSInteger iy = 0; iy < 8; ++iy) {
          for (NSInteger ix = 0; ix < 8; ++ix) {
            [midi setButtonColor:pressed ? PHLaunchpadColorGreenBright : PHLaunchpadColorOff atX:ix y:iy];
          }
        }
      }
      break;
    default:
      break;
  }
}

#pragma mark - Rendering

- (void)renderBitmapInContext:(CGContextRef)cx
                         size:(CGSize)size
                     spectrum:(float *)spectrum
       numberOfSpectrumValues:(NSInteger)numberOfSpectrumValues {
  CGSize wallSize = CGSizeMake(kWallWidth, kWallHeight);

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  if (nil == colorSpace) {
    return;
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
    return;
  }

  [_driver setSpectrum:spectrum numberOfValues:numberOfSpectrumValues];

  _animation.driver = _driver;
  CGContextClearRect(wallContext, CGRectMake(0, 0, wallSize.width, wallSize.height));
  [_animation renderBitmapInContext:wallContext
                               size:wallSize];

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
