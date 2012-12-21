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

#import "PHBassPlate.h"

@implementation PHBassPlate {
  CGImageRef _imageOfPreviousFrame;
  PHDegrader* _bassDegrader;
  NSTimeInterval _lastTick;
  CGFloat _advance;
  CGFloat _rotationAdvance;
}

- (id)init {
  if ((self = [super init])) {
    _bassDegrader = [[PHDegrader alloc] init];
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  if (self.driver.spectrum) {
    CGContextTranslateCTM(cx, size.width / 2, size.height / 2);
    CGContextRotateCTM(cx, _rotationAdvance);

    if (_imageOfPreviousFrame) {
      CGContextSaveGState(cx);
      CGContextSetAlpha(cx, 0.96);
      CGContextTranslateCTM(cx, -size.width / 2, -size.height / 2);
      CGContextDrawImage(cx, CGRectMake(1, 0, size.width - 2, size.height - 1), _imageOfPreviousFrame);
      CGContextRestoreGState(cx);
    }

    CGContextTranslateCTM(cx, -size.width / 2, -size.height / 2);
    CGFloat bass = self.driver.subBassAmplitude;
    [_bassDegrader tickWithPeak:bass];

    NSTimeInterval delta = [NSDate timeIntervalSinceReferenceDate] - _lastTick;
    _advance += delta * 10 * self.driver.hihatAmplitude;
    _rotationAdvance += delta * self.driver.snareAmplitude / 4;

    if (_bassDegrader.value > 0.01) {
      CGFloat red = sin(_advance) * 0.5 + 0.5;
      CGFloat green = cos(_advance + M_PI_2) * 0.5 + 0.5;
      CGFloat blue = sin(_advance - M_PI_4) * 0.5 + 0.5;
      CGContextSetRGBFillColor(cx, red, green, blue, 1);
      CGFloat bassLineWidth = size.width * _bassDegrader.value;
      CGContextFillRect(cx, CGRectMake(size.width / 2 - bassLineWidth / 2, size.height - 1, bassLineWidth, 1));
    }

    if (nil != _imageOfPreviousFrame) {
      CGImageRelease(_imageOfPreviousFrame);
    }
    _imageOfPreviousFrame = CGBitmapContextCreateImage(cx);

    _lastTick = [NSDate timeIntervalSinceReferenceDate];
  }
}

@end
