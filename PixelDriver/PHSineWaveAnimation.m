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

#import "PHSineWaveAnimation.h"

@implementation PHSineWaveAnimation {
  PHDegrader* _bassDegrader;
  PHDegrader* _snareDegrader;

  NSTimeInterval _lastTick;
  CGFloat _advance;
  CGFloat _advanceSin;
}

- (id)init {
  if ((self = [super init])) {
    _bassDegrader = [[PHDegrader alloc] init];
    _bassDegrader.deltaPerSecond = 1.2;
    _snareDegrader = [[PHDegrader alloc] init];
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  if (self.driver.unifiedSpectrum) {
    [_bassDegrader tickWithPeak:self.driver.subBassAmplitude];
    [_snareDegrader tickWithPeak:self.driver.hihatAmplitude];

    NSTimeInterval tick = [NSDate timeIntervalSinceReferenceDate];
    if (_lastTick > 0) {
      NSTimeInterval delta = tick - _lastTick;

      _advance += delta;
      _advanceSin += _bassDegrader.value * delta * 20;
    }

    CGRect pixelRect = CGRectMake(0, 0, 1, 1);
    for (int ix = 0; ix < size.width; ++ix) {
      pixelRect.origin.x = ix;
      for (int iy = 0; iy < size.height; ++iy) {
        pixelRect.origin.y = iy;

        float centery = size.height / 2;
        float sineAmplitude = sin((float)ix / 2 + _advanceSin);
        float sineWidth = _snareDegrader.value * 8;
        float sineOffset = centery + sineAmplitude * sineWidth;
        float offsety = sineOffset - iy;

        if (fabsf(offsety) <= sineWidth) {
          float amplitude = fabsf((sineWidth - fabsf(offsety)) / sineWidth);
          CGFloat red = (sin(_advance) * 0.5f + 0.5f);
          CGFloat green = (cos(_advance) * 0.5f + 0.5f);
          CGFloat blue = (sin(_advance) * cos(_advance) * 0.5f + 0.5f);

          CGContextSetRGBFillColor(cx, red, green, blue, amplitude);
          CGContextFillRect(cx, pixelRect);
        }
      }
    }

    _lastTick = [NSDate timeIntervalSinceReferenceDate];
  }
}

@end
