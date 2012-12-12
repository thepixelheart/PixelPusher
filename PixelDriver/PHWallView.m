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
#import "PHDriver.h"
#import "PHQuartzRenderer.h"
#import "Utilities.h"

const NSInteger kPixelBorderSize = 1;
const NSInteger kPixelSize = 16;

static CVReturn displayLinkCallback(CVDisplayLinkRef displayLink,
                                    const CVTimeStamp* now,
                                    const CVTimeStamp* outputTime,
                                    CVOptionFlags flagsIn,
                                    CVOptionFlags* flagsOut,
                                    void* displayLinkContext) {
  @autoreleasepool {
    [((__bridge PHWallView*)displayLinkContext) setNeedsDisplay:YES];
    return kCVReturnSuccess;
  }
}

@implementation PHWallView {
  PHQuartzRenderer *_renderer;
  CVDisplayLinkRef _displayLink;
  NSDate* _firstTick;
}

- (void)dealloc {
  CVDisplayLinkRelease(_displayLink);
}

- (void)awakeFromNib {
  [super awakeFromNib];

  NSString* filename = @"PixelDriver.app/Contents/Resources/tree.qtz";
  _renderer = [[PHQuartzRenderer alloc] initWithCompositionPath:filename
                                                     pixelsWide:kWallWidth
                                                     pixelsHigh:kWallHeight];

  [self driverConnectionDidChange];

  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(driverConnectionDidChange)
             name:PHDriverConnectionStateDidChangeNotification
           object:nil];

  if (kCVReturnSuccess != CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink)) {
    PHAlert(@"Unable to set up a timer for the animations.");
    return;
  }
  CVDisplayLinkSetOutputCallback(_displayLink, &displayLinkCallback, (__bridge void*)self);
  CVDisplayLinkStart(_displayLink);

  _firstTick = [NSDate date];
}

#pragma mark - Rendering

- (void)drawRect:(NSRect)dirtyRect {
  [super drawRect:dirtyRect];

  CGContextRef cx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
  [[NSColor blackColor] set];
  CGContextFillRect(cx, self.bounds);

  if (PHApp().driver.isConnected) {
    [[NSColor colorWithDeviceRed:32.f / 255.f green:32.f / 255.f blue:32.f / 255.f alpha:1] set];
  } else {
    [[NSColor colorWithDeviceRed:64.f / 255.f green:32.f / 255.f blue:32.f / 255.f alpha:1] set];
  }
  CGRect frame = CGRectMake(0, 0, kPixelBorderSize, self.bounds.size.height);
  for (NSInteger ix = 0; ix <= kWallWidth; ++ix) {
    frame.origin.x = ix * (kPixelBorderSize + kPixelSize);
    CGContextFillRect(cx, frame);
  }
  frame = CGRectMake(0, 0, self.bounds.size.width, kPixelBorderSize);
  for (NSInteger iy = 0; iy <= kWallHeight; ++iy) {
    frame.origin.y = iy * (kPixelBorderSize + kPixelSize);
    CGContextFillRect(cx, frame);
  }

  NSBitmapImageRep* bitmap = [_renderer bitmapImageForTime:[[NSDate date] timeIntervalSinceDate:_firstTick]];
  NSRect pixelFrame = NSMakeRect(0, 0, 1, 1);
  NSRect viewFrame = NSMakeRect(0, 0, kPixelSize, kPixelSize);
  NSDictionary* hints = @{NSImageHintInterpolation: [NSNumber numberWithInt:NSImageInterpolationNone]};
  for (NSInteger iy = 0; iy < kWallHeight; ++iy) {
    pixelFrame.origin.y = iy;
    viewFrame.origin.y = (iy + 1) * kPixelBorderSize + iy * kPixelSize;

    for (NSInteger ix = 0; ix < kWallWidth; ++ix) {
      pixelFrame.origin.x = ix;
      viewFrame.origin.x = (ix + 1) * kPixelBorderSize + ix * kPixelSize;
      [bitmap drawInRect:viewFrame fromRect:pixelFrame
               operation:NSCompositeCopy fraction:1 respectFlipped:NO hints:hints];
    }
  }

  [PHApp().driver setFrameBitmap:bitmap];
  [bitmap draw];
}

#pragma mark - Driver Notifications

- (void)driverConnectionDidChange {
  if (PHApp().driver.isConnected) {
    NSLog(@"Driver is attached");
  } else {
    NSLog(@"Driver is detached");
  }
  [self setNeedsDisplay:YES];
}

@end
