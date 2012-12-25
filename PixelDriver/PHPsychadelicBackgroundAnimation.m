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

#import "PHPsychadelicBackgroundAnimation.h"

@implementation PHPsychadelicBackgroundAnimation {
  PHDegrader* _bassDegrader;
  PHDegrader* _snareDegrader;

  CGFloat _advance;
  CGFloat _colorAdvance;
  CGFloat _rotationAdvance;
  NSTimeInterval _lastTick;
  CGFloat _direction;
  BOOL _didSwap;
}

- (id)init {
  if ((self = [super init])) {
    _bassDegrader = [[PHDegrader alloc] init];
    _bassDegrader.deltaPerSecond = 1.2;
    _snareDegrader = [[PHDegrader alloc] init];
    _direction = 1;
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  if (self.driver.unifiedSpectrum) {
    [_bassDegrader tickWithPeak:self.driver.subBassAmplitude];
    [_snareDegrader tickWithPeak:self.driver.hihatAmplitude];

    if (_lastTick) {
      NSTimeInterval delta = [NSDate timeIntervalSinceReferenceDate] - _lastTick;
      if (_bassDegrader.value < 0.4) {
        if (!_didSwap) {
          _direction = -_direction;
          _didSwap = YES;
        }
      } else {
        _didSwap = NO;
      }
      _advance += delta * 1 * _bassDegrader.value * _direction;
      _colorAdvance += delta * 3 * _snareDegrader.value * _direction;
      _rotationAdvance += delta * 2 * self.driver.vocalAmplitude * _direction;
    }
    CGRect pixelRect = CGRectMake(0, 0, 1, 1);
    for (int ix = 0; ix < size.width; ++ix) {
      pixelRect.origin.x = ix;

      CGFloat x = (CGFloat)((size.width / 2 - ix) * cos(_advance))  / size.width * 4 + _advance * 2;

      for (int iy = 0; iy < size.height; ++iy) {
        pixelRect.origin.y = iy;

        CGFloat y = (CGFloat)((size.height / 2 - iy) * sin(_advance / 10)) / size.height * 4 + _advance * 1.4;

        CGFloat red = (sin(x + y + _colorAdvance) * 0.5f + 0.5f);
        CGFloat green = (cos(y + _colorAdvance) * 0.5f + 0.5f);
        CGFloat blue = (sin(x - _colorAdvance) * cos(y + x - _colorAdvance) * 0.5f + 0.5f);

        CGContextSetRGBFillColor(cx, red, green, blue, 1);
        CGContextFillRect(cx, pixelRect);
      }
    }

    _lastTick = [NSDate timeIntervalSinceReferenceDate];
  }
}

@end
