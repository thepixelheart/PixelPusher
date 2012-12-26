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

#import "PHSimpleMoteAnimation.h"

@implementation PHSimpleMoteAnimation {
  PHDegrader* _aButtonDegrader;
  PHDegrader* _bButtonDegrader;
}

- (id)init {
  if ((self = [super init])) {
    _aButtonDegrader = [[PHDegrader alloc] init];
    _bButtonDegrader = [[PHDegrader alloc] init];
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  if (self.driver.unifiedSpectrum) {
    CGFloat circleRadius = 5;
    CGRect circleFrame = CGRectMake(0, 0, circleRadius * 2, circleRadius * 2);
    CGFloat maxRadius = MIN(size.height, size.width) / 2 - circleRadius;

    for (PHMote* mote in self.driver.motes) {
      CGFloat degrees = mote.joystickDegrees;
      CGFloat radians = degrees * M_PI / 180;
      CGFloat tilt = mote.joystickTilt;

      [_aButtonDegrader tickWithPeak:(mote.numberOfTimesATapped > 0) ? 1 : 0];
      [_bButtonDegrader tickWithPeak:(mote.numberOfTimesBTapped > 0) ? 1 : 0];

      if (_aButtonDegrader.value > 0) {
        CGContextSetRGBFillColor(cx, 0, 1, 0, _aButtonDegrader.value);
        CGContextFillRect(cx, CGRectMake(0, 0, size.width / 2, size.height));
      }
      if (_bButtonDegrader.value > 0) {
        CGContextSetRGBFillColor(cx, 0, 0, 1, _bButtonDegrader.value);
        CGContextFillRect(cx, CGRectMake(size.width / 2, 0, size.width / 2, size.height));
      }

      CGRect moteFrame = circleFrame;
      moteFrame.origin.x = size.width / 2 - circleRadius + cosf(radians) * tilt * maxRadius;
      moteFrame.origin.y = size.height / 2 - circleRadius + sinf(radians) * tilt * maxRadius;
      CGContextSetRGBFillColor(cx, 1, 0, 0, 1);
      CGContextFillEllipseInRect(cx, moteFrame);
    }
  }
}

@end
