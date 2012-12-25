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

#import "AppDelegate.h"
#import "PHDriver.h"

#define NHISTOGRAMS 4

@implementation PHBouncingCircleAnimation {
  CGFloat _maxes[8];
  NSTimeInterval _lastTick;
  CGFloat _totalMax;

  CGFloat _histograms[48*NHISTOGRAMS];
}

- (id)init {
  if ((self = [super init])) {
    memset(_maxes, 0, sizeof(CGFloat) * 8);
    memset(_histograms, 0, sizeof(CGFloat) * 48 * NHISTOGRAMS);
    _lastTick = [NSDate timeIntervalSinceReferenceDate];
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  if (self.driver.unifiedSpectrum) {
    CGFloat histogramHeight = floorf(kWallHeight / NHISTOGRAMS);
    for (NSInteger ix = 0; ix < NHISTOGRAMS; ++ix) {
      NSColor* color = nil;
      if (ix == 0) {
        color = [NSColor colorWithDeviceRed:1 green:0 blue:0 alpha:1];
      } else if (ix == 1) {
        color = [NSColor colorWithDeviceRed:0 green:1 blue:0 alpha:1];
      } else if (ix == 2) {
        color = [NSColor colorWithDeviceRed:0 green:0 blue:1 alpha:1];
      } else if (ix == 3) {
        color = [NSColor colorWithDeviceRed:1 green:0 blue:1 alpha:1];
      }

      // Shift all values back.
      for (NSInteger col = 0; col < kWallWidth - 1; ++col) {
        _histograms[ix * 48 + col] = _histograms[ix * 48 + col + 1];
      }

      _lastTick = [NSDate timeIntervalSinceReferenceDate];

      CGFloat amplitude = 0;
      if (ix == 0) {
        amplitude = self.driver.subBassAmplitude;
      } else if (ix == 1) {
        amplitude = self.driver.hihatAmplitude;
      } else if (ix == 2) {
        amplitude = self.driver.vocalAmplitude;
      } else if (ix == 3) {
        amplitude = self.driver.snareAmplitude;
      }
      _histograms[ix * 48 + 47] = amplitude;
      CGContextSetFillColorWithColor(cx, color.CGColor);
      for (NSInteger col = 0; col < kWallWidth; ++col) {
        CGFloat val = _histograms[col + ix * 48];
        CGFloat height = val * histogramHeight;
        CGRect line = CGRectMake(col, (ix + 1) * histogramHeight - height, 1, height);
        CGContextFillRect(cx, line);
      }
    }
    
    /*
    NSInteger chunkSize = self.driver.numberOfSpectrumValues / 8;
    NSTimeInterval delta = [NSDate timeIntervalSinceReferenceDate] - _lastTick;

    for (NSInteger maxix = 0; maxix < 8; ++maxix) {
      CGFloat max = _maxes[maxix];

      CGFloat average = 0;
      for (NSInteger ix = maxix * chunkSize; ix < (maxix + 1) * chunkSize; ++ix) {
        average += self.driver.spectrum[ix] / 0.002;
      }
      average /= (CGFloat)chunkSize;
      average = MIN(average, 1);

      if (maxix == 0) {
        average = self.driver.subBassAmplitude;
      } else if (maxix == 1) {
        average = self.driver.hihatAmplitude;
      } else if (maxix == 2) {
        average = self.driver.vocalAmplitude;
      }

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
      } else if (maxix == 5) {
        color = [NSColor colorWithDeviceRed:0.25 green:0.5 blue:0.75 alpha:1];
      } else if (maxix == 6) {
        color = [NSColor colorWithDeviceRed:0.75 green:0 blue:0.5 alpha:1];
      } else {
        color = [NSColor colorWithDeviceRed:0 green:1 blue:1 alpha:1];
      }
      CGContextSetFillColorWithColor(cx, color.CGColor);

      NSInteger xCol = maxix % 4;
      NSInteger yCol = maxix / 4;
      CGFloat leftEdge = xCol * kWallWidth / 4;
      CGFloat bottomEdge = (yCol + 1) * kWallHeight / 2;

      CGRect boundingRect = CGRectMake(leftEdge, bottomEdge - kWallHeight / 2 + kWallWidth / 16, kWallWidth / 4, kWallWidth / 4);
      CGFloat shrinkAmount = ((kWallWidth / 4) / 2) * (1 - max);
      CGRect shrunkRect = CGRectInset(boundingRect, shrinkAmount, shrinkAmount);
      CGContextFillEllipseInRect(cx, shrunkRect);
//      CGContextFillRect(cx, CGRectMake(leftEdge, bottomEdge - max * kTileHeight, kTileWidth, max * kTileHeight));
    }
    _lastTick = [NSDate timeIntervalSinceReferenceDate];*/
  }
}

@end
