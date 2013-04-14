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

#import "PHFlashTransition.h"

#import <QuartzCore/CoreImage.h>

@implementation PHFlashTransition {
  NSTimeInterval _lastTick;
  NSTimeInterval _accum;
}

- (void)renderBitmapInContext:(CGContextRef)cx
                         size:(CGSize)size
                  leftContext:(CGContextRef)leftContext
                 rightContext:(CGContextRef)rightContext
                            t:(CGFloat)t {
  if (_lastTick != 0) {
    NSTimeInterval delta = [NSDate timeIntervalSinceReferenceDate] - _lastTick;
    delta = MIN(1, delta);
    _accum += delta;
  }

  CGFloat offset = _accum;
  CGFloat red = sin(offset) * 0.5 + 0.5;
  CGFloat green = cos(offset * 5 + M_PI_2) * 0.5 + 0.5;
  CGFloat blue = sin(offset * 13 - M_PI_4) * 0.5 + 0.5;

  CGRect frame = CGRectMake(0, 0, size.width, size.height);
  CGContextSaveGState(cx);

  CGImageRef leftImageContextRef = CGBitmapContextCreateImage(leftContext);
  CIImage *leftImage = [CIImage imageWithCGImage:leftImageContextRef];
  CGImageRelease(leftImageContextRef);

  CGImageRef rightImageContextRef = CGBitmapContextCreateImage(rightContext);
  CIImage *rightImage = [CIImage imageWithCGImage:rightImageContextRef];
  CGImageRelease(rightImageContextRef);

  CIFilter *filter = [CIFilter filterWithName:@"CIFlashTransition"];
  [filter setValue:leftImage forKey:kCIInputImageKey];
  [filter setValue:rightImage forKey:kCIInputTargetImageKey];
  [filter setValue:[CIVector vectorWithX:size.width / 2 Y:size.height / 2] forKey:kCIInputCenterKey];
  [filter setValue:[CIVector vectorWithX:0 Y:0 Z:size.width W:size.height] forKey:kCIInputExtentKey];
  [filter setValue:[CIColor colorWithRed:red green:green blue:blue] forKey:kCIInputColorKey];
  [filter setValue:@(t) forKey:kCIInputTimeKey];
  [filter setValue:@(2.58) forKey:@"inputMaxStriationRadius"];
  [filter setValue:@(0.5) forKey:@"inputStriationStrength"];
  [filter setValue:@(1.38) forKey:@"inputStriationContrast"];
  [filter setValue:@(0.5) forKey:@"inputFadeThreshold"];

  CIImage *result = [filter valueForKey:kCIOutputImageKey];
  CGRect sourceFrame = CGRectMake(0, 0, size.width, size.height);

  NSGraphicsContext* previousContext = [NSGraphicsContext currentContext];
  NSGraphicsContext* graphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:cx flipped:NO];
  [NSGraphicsContext setCurrentContext:graphicsContext];
  [result drawInRect:frame fromRect:sourceFrame operation:NSCompositeCopy fraction:1];
  [NSGraphicsContext setCurrentContext:previousContext];

  CGContextRestoreGState(cx);

  _lastTick = [NSDate timeIntervalSinceReferenceDate];
}

- (NSString *)tooltipName {
  return @"Flash";
}

@end
