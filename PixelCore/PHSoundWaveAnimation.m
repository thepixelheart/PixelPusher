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

#import "PHSoundWaveAnimation.h"

@implementation PHSoundWaveAnimation {
  CGFloat _colorAdvance;
  CGFloat _values[48];
}

- (id)init {
  if ((self = [super init])) {
    memset(_values, 0, sizeof(CGFloat) * 48);
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  _colorAdvance += self.secondsSinceLastTick;
  CGContextSaveGState(cx);

  NSInteger numberOfWaveDataValues = self.systemState.numberOfWaveDataValues;
  float* unifiedWaveData = self.systemState.unifiedWaveData + self.systemState.numberOfWaveDataValues - numberOfWaveDataValues;
  NSInteger numberOfValuesPerStep = floorf(numberOfWaveDataValues / size.width);

  for (NSInteger ix = 0; ix < size.width; ++ix) {
    NSInteger leftCol = numberOfValuesPerStep * ix;
    NSInteger rightCol = numberOfValuesPerStep * (ix + 1);
    CGFloat amplitude = 0;
    for (NSInteger wavex = leftCol; wavex < rightCol; ++wavex) {
      amplitude += unifiedWaveData[wavex];
    }
    amplitude /= (CGFloat)numberOfValuesPerStep;

    CGFloat value;
    _values[(int)ix] -= _values[(int)ix] * self.secondsSinceLastTick * 10;
    if (fabs(amplitude) > fabs(_values[(int)ix])) {
      value = amplitude;
      _values[(int)ix] = amplitude;
    } else {
      value = _values[(int)ix];
    }
    CGPoint position = CGPointMake(ix, value * size.height * 0.8 + size.height / 2);
    if (ix == 0) {
      CGContextMoveToPoint(cx, position.x, position.y);
    } else {
      CGContextAddLineToPoint(cx, position.x, position.y);
    }
  }

  CGFloat offset = _colorAdvance;
  CGFloat red = sin(offset * 3) * 0.3 + 0.7;
  CGFloat green = cos(offset * 5 + M_PI_2) * 0.3 + 0.7;
  CGFloat blue = sin(offset * 7 - M_PI_4) * 0.3 + 0.7;
  CGContextSetStrokeColorWithColor(cx, [NSColor colorWithDeviceRed:red green:green blue:blue alpha:1].CGColor);
  CGContextStrokePath(cx);

  CGContextRestoreGState(cx);
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  [self renderBitmapInContext:cx size:size];
}

- (NSString *)tooltipName {
  return @"Sound Wave";
}

@end
