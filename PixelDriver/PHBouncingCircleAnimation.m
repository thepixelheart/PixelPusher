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

#import "PHBouncingCircleAnimation.h"

#import "PHDriver.h"

@implementation PHBouncingCircleAnimation {
  CGFloat _maxes[6];
  NSTimeInterval _lastTick;
  CGFloat _totalMax;
}

- (id)init {
  if ((self = [super init])) {
    memset(_maxes, 0, sizeof(CGFloat) * 6);
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size spectrum:(float *)spectrum numberOfSpectrumValues:(NSInteger)numberOfSpectrumValues {
  if (spectrum) {
    NSInteger chunkSize = numberOfSpectrumValues / 6;
    NSTimeInterval delta = [NSDate timeIntervalSinceReferenceDate] - _lastTick;

    for (NSInteger maxix = 0; maxix < 6; ++maxix) {
      CGFloat max = _maxes[maxix];

      CGFloat average = 0;
      for (NSInteger ix = maxix * chunkSize; ix < (maxix + 1) * chunkSize; ++ix) {
        if (maxix == 0) {
          average += spectrum[ix] / 0.01;
        } else {
          average += spectrum[ix] / 0.004;
        }
      }
      average /= (CGFloat)chunkSize;
      average = MIN(average, 1);

      max = MAX(max, average);
      max -= delta * 1;
      max = MAX(0, max);

      _maxes[maxix] = max;

      NSColor* color = nil;
      if (maxix == 0) {
        color = [NSColor colorWithDeviceRed:1 green:0 blue:0 alpha:1];
      } else if (maxix == 1) {
        color = [NSColor colorWithDeviceRed:0 green:1 blue:0 alpha:1];
      } else if (maxix == 2) {
        color = [NSColor colorWithDeviceRed:0 green:0 blue:1 alpha:1];
      } else if (maxix == 3) {
        color = [NSColor colorWithDeviceRed:1 green:0 blue:1 alpha:1];
      } else if (maxix == 4) {
        color = [NSColor colorWithDeviceRed:1 green:1 blue:0 alpha:1];
      } else {
        color = [NSColor colorWithDeviceRed:0 green:1 blue:1 alpha:1];
      }
      CGContextSetFillColorWithColor(cx, color.CGColor);

      NSInteger xCol = maxix % 3;
      NSInteger yCol = maxix / 3;
      CGFloat leftEdge = xCol * kTileWidth;
      CGFloat bottomEdge = (yCol + 1) * kTileHeight;

      CGRect boundingRect = CGRectMake(leftEdge, bottomEdge - kTileHeight, kTileWidth, kTileHeight);
      CGFloat shrinkAmount = (kTileHeight / 2) * (1 - max);
      CGRect shrunkRect = CGRectInset(boundingRect, shrinkAmount, shrinkAmount);
      CGContextFillEllipseInRect(cx, shrunkRect);
//      CGContextFillRect(cx, CGRectMake(leftEdge, bottomEdge - max * kTileHeight, kTileWidth, max * kTileHeight));
    }
    _lastTick = [NSDate timeIntervalSinceReferenceDate];
  }
}

@end
