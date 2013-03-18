//
// Copyright 2012-2013 Jeff Verkoeyen
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
#import "PHSystemTick.h"
#import "PHBitmapPipeline.h"
#import "PHDisplayLink.h"
#import "PHDriver.h"
#import "PHFMODRecorder.h"
#import "PHMIDIDriver.h"
#import "PHQuartzRenderer.h"
#import "PHSystem.h"
#import "Utilities.h"

// Animations
#import "PHAnimation.h"

/*
  PHQuartzRenderer *_renderer;

  NSString* filename = @"PixelDriver.app/Contents/Resources/clouds.qtz";
  _renderer = [[PHQuartzRenderer alloc] initWithCompositionPath:filename
                                                     pixelsWide:kWallWidth
                                                     pixelsHigh:kWallHeight];
*/
@implementation PHWallView

#pragma mark - Rendering

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size driver:(PHSystemState *)driver systemTick:(PHSystemTick *)systemTick {
  CGContextSetRGBFillColor(cx, 0, 0, 0, 1);
  CGRect bounds = CGRectMake(0, 0, size.width, size.height);
  CGContextFillRect(cx, bounds);

  CGContextRef wallContext = nil;
  if (_systemContext == PHSystemContextLeft) {
    wallContext = systemTick.leftContextRef;
  } else if (_systemContext == PHSystemContextRight) {
    wallContext = systemTick.rightContextRef;
  } else if (_systemContext == PHSystemContextPreview) {
    wallContext = systemTick.previewContextRef;
  } else if (_systemContext == PHSystemContextWall) {
    wallContext = systemTick.wallContextRef;
  }
  if (nil == wallContext) {
    return;
  }

  CGContextSetInterpolationQuality(cx, kCGInterpolationNone);

  CGImageRef imageRef = CGBitmapContextCreateImage(wallContext);
  CGContextScaleCTM(cx, 1, -1);
  CGContextTranslateCTM(cx, 0, -size.height);
  CGContextDrawImage(cx, self.bounds, imageRef);
  CGImageRelease(imageRef);
}

- (double)threadPriority {
  return 0.7;
}

@end
