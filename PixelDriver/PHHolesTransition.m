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

#import "PHHolesTransition.h"

#import <QuartzCore/CoreImage.h>

@implementation PHHolesTransition {
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

  CGRect frame = CGRectMake(0, 0, size.width, size.height);
  CGContextSaveGState(cx);

  CGImageRef leftImageContextRef = CGBitmapContextCreateImage(leftContext);
  CIImage *leftImage = [CIImage imageWithCGImage:leftImageContextRef];
  CGImageRelease(leftImageContextRef);

  CGImageRef rightImageContextRef = CGBitmapContextCreateImage(rightContext);
  CIImage *rightImage = [CIImage imageWithCGImage:rightImageContextRef];
  CGImageRelease(rightImageContextRef);

  CIFilter *filter = [CIFilter filterWithName:@"CIModTransition"];
  [filter setValue:leftImage forKey:kCIInputImageKey];
  [filter setValue:rightImage forKey:kCIInputTargetImageKey];
  [filter setValue:[CIVector vectorWithX:size.width / 2 Y:size.height / 2] forKey:kCIInputCenterKey];
  [filter setValue:@(t) forKey:kCIInputTimeKey];
  [filter setValue:@(sin(_accum * 5) * cos(_accum * 7) * 0.5 * 2 - 0.5) forKey:kCIInputAngleKey];
  [filter setValue:@(10) forKey:kCIInputRadiusKey];
  [filter setValue:@(20) forKey:@"inputCompression"];

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
  return @"Holes";
}

@end
