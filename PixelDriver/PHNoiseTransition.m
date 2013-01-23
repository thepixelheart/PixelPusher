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

#import "PHNoiseTransition.h"

#import "PHDriver.h"

static const int kNoiseCount = 48 * 32;
CGRect noiseRects[kNoiseCount];

@implementation PHNoiseTransition

+ (void)initialize {
  NSMutableArray* indices = [NSMutableArray arrayWithCapacity:kNoiseCount];
  for (int ix = 0; ix < kNoiseCount; ++ix) {
    [indices addObject:[NSNumber numberWithInt:ix]];
  }

  for (int i = 0; i < kNoiseCount; ++i) {
    // Select a random element between i and end of array to swap with.
    int nElements = kNoiseCount - i;
    int n = arc4random_uniform(nElements) + i;
    [indices exchangeObjectAtIndex:i withObjectAtIndex:n];
  }

  for (int ix = 0; ix < kNoiseCount; ++ix) {
    int index = [indices[ix] intValue];
    CGFloat x = index % kWallWidth;
    CGFloat y = floor(index / kWallWidth);
    noiseRects[ix].origin.x = x;
    noiseRects[ix].origin.y = y;
    noiseRects[ix].size.width = 1;
    noiseRects[ix].size.height = 1;
  }
}

- (void)renderBitmapInContext:(CGContextRef)cx
                         size:(CGSize)size
                  leftContext:(CGContextRef)leftContext
                 rightContext:(CGContextRef)rightContext
                            t:(CGFloat)t {
  CGRect frame = CGRectMake(0, 0, size.width, size.height);
  CGContextSaveGState(cx);
  if (nil != leftContext && t < 1) {
    CGContextSaveGState(cx);
    CGImageRef leftImage = CGBitmapContextCreateImage(leftContext);
    CGContextClipToRects(cx, noiseRects, kNoiseCount * (1 - t));
    CGContextDrawImage(cx, frame, leftImage);
    CGImageRelease(leftImage);
    CGContextRestoreGState(cx);
  }
  if (nil != rightContext && t > 0) {
    CGContextSaveGState(cx);
    CGImageRef rightImage = CGBitmapContextCreateImage(rightContext);
    CGContextClipToRects(cx, noiseRects + (int)((1 - t) * kNoiseCount), kNoiseCount * t);
    CGContextDrawImage(cx, frame, rightImage);
    CGImageRelease(rightImage);
    CGContextRestoreGState(cx);
  }

  CGContextRestoreGState(cx);
}

- (NSString *)tooltipName {
  return @"Noise";
}

@end
