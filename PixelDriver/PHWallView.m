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

const NSInteger kPixelBorderSize = 1;

@implementation PHWallWindow
@end

@implementation PHWallView {
  PHQuartzRenderer *_renderer;
  NSDate* _firstTick;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
  [super awakeFromNib];
/*
  NSString* filename = @"PixelDriver.app/Contents/Resources/clouds.qtz";
  _renderer = [[PHQuartzRenderer alloc] initWithCompositionPath:filename
                                                     pixelsWide:kWallWidth
                                                     pixelsHigh:kWallHeight];
*/
  _firstTick = [NSDate date];
}

#pragma mark - Rendering

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size driver:(PHAnimationDriver *)driver {
  CGContextSetRGBFillColor(cx, 0, 0, 0, 1);
  CGRect bounds = CGRectMake(0, 0, size.width, size.height);
  CGContextFillRect(cx, bounds);

  if (PHApp().driver.isConnected || !_primary) {
    CGContextSetRGBFillColor(cx, 32.f / 255.f, 32.f / 255.f, 32.f / 255.f, 1);
  } else {
    CGContextSetRGBFillColor(cx, 64.f / 255.f, 64.f / 255.f, 64.f / 255.f, 1);
  }
  CGRect frame = CGRectMake(0, 0, kPixelBorderSize, size.height);
  for (NSInteger ix = 0; ix <= kWallWidth; ++ix) {
    frame.origin.x = ix * (kPixelBorderSize + _pixelSize);
    CGContextFillRect(cx, frame);
  }
  frame = CGRectMake(0, 0, size.width, kPixelBorderSize);
  for (NSInteger iy = 0; iy <= kWallHeight; ++iy) {
    frame.origin.y = iy * (kPixelBorderSize + _pixelSize);
    CGContextFillRect(cx, frame);
  }

  CGContextRef wallContext;
  if (_primary) {
    wallContext = [PHApp() currentWallContext];
  } else {
    wallContext = [PHApp() previewWallContext];
  }
  if (nil == wallContext) {
    return;
  }

  if (_primary) {
    [PHApp().driver queueContext:wallContext];
  }

  float* data = (float *)CGBitmapContextGetData(wallContext);
  size_t bytesPerRow = CGBitmapContextGetBytesPerRow(wallContext);

  NSRect pixelFrame = NSMakeRect(0, 0, 1, 1);
  NSRect viewFrame = NSMakeRect(0, 0, _pixelSize, _pixelSize);
  for (NSInteger iy = 0; iy < kWallHeight; ++iy) {
    pixelFrame.origin.y = iy;
    viewFrame.origin.y = (iy + 1) * kPixelBorderSize + iy * _pixelSize;

    for (NSInteger ix = 0; ix < kWallWidth; ++ix) {
      pixelFrame.origin.x = ix;
      viewFrame.origin.x = (ix + 1) * kPixelBorderSize + ix * _pixelSize;

      NSInteger offset = ix * 4 + iy * (bytesPerRow / 4);
      CGContextSetRGBFillColor(cx, data[offset] / data[offset + 3], data[offset + 1] / data[offset + 3], data[offset + 2] / data[offset + 3], data[offset + 3]);
      CGContextFillRect(cx, viewFrame);
    }
  }

  CGContextRelease(wallContext);
}

- (double)threadPriority {
  return _primary ? 0.9 : 0.7;
}

@end
