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

#import "PHSoundBoxAnimation.h"

static const NSInteger kNumberOfSteps = 90;
static const CGFloat kMinRadius = 4;

@implementation PHSoundBoxAnimation {
  CGFloat _scalers[kNumberOfSteps];
  CGFloat _peaks[kNumberOfSteps];
  CGFloat _colorAdvance;
}

- (id)init {
  if ((self = [super init])) {
    for (NSInteger ix = 0; ix < kNumberOfSteps; ++ix) {
      _scalers[ix] = 1000000;
      _peaks[ix] = 0;
    }
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);

  _colorAdvance += self.secondsSinceLastTick * 0.3;

  NSInteger numberOfSpectrumValues = self.systemState.numberOfHighResSpectrumValues * 0.5;
  float* spectrumValues = self.systemState.highResUnifiedSpectrum;
  NSInteger numberOfValuesPerStep = floorf(numberOfSpectrumValues / kNumberOfSteps);

  CGFloat stepSize = M_PI * 2 / (CGFloat)kNumberOfSteps;

  for (NSInteger ix = 0; ix < kNumberOfSteps; ++ix) {
    CGFloat amplitude = 0;

    NSInteger leftCol = numberOfValuesPerStep * ix;
    NSInteger rightCol = numberOfValuesPerStep * (ix + 1);
    for (NSInteger spectrumx = leftCol; spectrumx < rightCol; ++spectrumx) {
      amplitude += spectrumValues[spectrumx];
    }

    amplitude /= (float)(numberOfValuesPerStep);
    _scalers[ix] = (_scalers[ix] + 0.01);
    float scaledAmplitude = amplitude * (_scalers[ix]);
    if (scaledAmplitude > 1) {
      _scalers[ix] = 1 / amplitude;
      scaledAmplitude = 1;
    }

    _peaks[ix] = MAX(0, _peaks[ix] - self.secondsSinceLastTick * 2);
    _peaks[ix] = MAX(_peaks[ix], scaledAmplitude);

    CGFloat radian = (CGFloat)ix * stepSize + stepSize / 2;

    CGPoint position = CGPointMake(sin(radian) * (kMinRadius + _peaks[ix] * (kWallHeight / 2 - kMinRadius)) + kWallWidth / 2,
                                   cos(radian) * (kMinRadius + _peaks[ix] * (kWallHeight / 2 - kMinRadius)) + kWallHeight / 2);
    if (ix == 0) {
      CGContextMoveToPoint(cx, position.x, position.y);
    } else {
      CGContextAddLineToPoint(cx, position.x, position.y);
    }
  }

  CGContextClosePath(cx);

  CGFloat offset = _colorAdvance;
  CGFloat red = sin(offset * 3) * 0.4 + 0.6;
  CGFloat green = cos(offset * 5 + M_PI_2) * 0.4 + 0.6;
  CGFloat blue = sin(offset * 7 - M_PI_4) * 0.4 + 0.6;
  CGContextSetStrokeColorWithColor(cx, [NSColor colorWithDeviceRed:red green:green blue:blue alpha:1].CGColor);

  CGContextStrokePath(cx);

  CGContextRestoreGState(cx);
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  [self renderBitmapInContext:cx size:size];
}

- (NSString *)tooltipName {
  return @"Soundbox";
}

@end
