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

#import "PHFlyingFireballAnimation.h"

@implementation PHFlyingFireballAnimation {
  CGImageRef _imageOfPreviousFrame;
  PHDegrader* _bassDegrader;
  PHDegrader* _movementDegrader;
  CGFloat _advance;
  CGFloat _advance2;
  NSTimeInterval _lastTick;
}

- (id)init {
  if ((self = [super init])) {
    _bassDegrader = [[PHDegrader alloc] init];
    _movementDegrader = [[PHDegrader alloc] init];
    _movementDegrader.deltaPerSecond = 4;
  }
  return self;
}

- (void)renderBall1AtX:(CGFloat)xOff1 context:(CGContextRef)cx {
  CGFloat radius = _bassDegrader.value * 5 + 1;
  CGFloat yOff = cos(_advance * 4) * 7;
  CGRect frame = CGRectMake(kWallWidth - radius * 2 - 15 + xOff1,
                            kWallHeight / 2 - radius + yOff - 5,
                            radius * 2,
                            radius * 2);
  size_t num_locations = 2;
  CGFloat locations[2] = { 0.0, 1.0 };
  CGFloat components[8] = {
    (sin(_advance) / 4) + 0.5,  (cos(_advance * 2) / 4) + 0.2,  (cos(_advance) * sin(_advance * 2) / 4) + 0.2, 1.0,
    0.4,  0,0  , 0 };

  CGColorSpaceRef myColorspace = CGColorSpaceCreateDeviceRGB();
  CGGradientRef myGradient = CGGradientCreateWithColorComponents(myColorspace, components, locations, num_locations);
  CGColorSpaceRelease(myColorspace);

  CGPoint midPoint = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
  CGContextDrawRadialGradient (cx, myGradient, midPoint,
                               0, midPoint, radius * 2,
                               kCGGradientDrawsBeforeStartLocation);
  CGGradientRelease(myGradient);
}

- (void)renderBall2AtX:(CGFloat)xOff2 context:(CGContextRef)cx {
  CGFloat radius = _movementDegrader.value * 7 + 3;
  CGFloat yOff = cos(_advance2 * 3) * 7;
  CGRect frame = CGRectMake(kWallWidth - radius * 2 - 15 + xOff2,
                            kWallHeight / 2 - radius + yOff + 5,
                            radius * 2,
                            radius * 2);
  size_t num_locations = 2;
  CGFloat locations[2] = { 0.0, 1.0 };
  CGFloat components[8] = {
    (cos(_advance2) * sin(_advance2 * 2) / 4) + 0.2,  (cos(_advance2 * 2) / 4) + 0.2,  (sin(_advance2) / 4) + 0.5, 1.0,
    0,  0,0.4, 0 };

  CGColorSpaceRef myColorspace = CGColorSpaceCreateDeviceRGB();
  CGGradientRef myGradient = CGGradientCreateWithColorComponents(myColorspace, components, locations, num_locations);
  CGColorSpaceRelease(myColorspace);

  CGPoint midPoint = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
  CGContextDrawRadialGradient (cx, myGradient, midPoint,
                               0, midPoint, radius * 2,
                               kCGGradientDrawsBeforeStartLocation);
  CGGradientRelease(myGradient);
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  if (self.driver.spectrum) {
    [_bassDegrader tickWithPeak:self.driver.subBassAmplitude];
    [_movementDegrader tickWithPeak:self.driver.hihatAmplitude];

    NSTimeInterval delta = [NSDate timeIntervalSinceReferenceDate] - _lastTick;

    _advance += delta * (_movementDegrader.value + 0.2);
    _advance2 += delta * (_bassDegrader.value + 0.2);

    CGContextSetBlendMode(cx, kCGBlendModeScreen);
    if (_imageOfPreviousFrame) {
      CGContextSaveGState(cx);
      CGContextSetAlpha(cx, 0.96);
      CGContextDrawImage(cx, CGRectInset(CGRectMake(-1, 0, size.width, size.height), 0, _bassDegrader.value * 4 - 2),
                         _imageOfPreviousFrame);
      CGContextRestoreGState(cx);
    }

    CGFloat xOff1 = sin(_advance) * 15;
    CGFloat xOff2 = sin(_advance2 * 2) * 15;

    if (xOff1 < xOff2) {
      [self renderBall1AtX:xOff1 context:cx];
      [self renderBall2AtX:xOff2 context:cx];
    } else {
      [self renderBall2AtX:xOff2 context:cx];
      [self renderBall1AtX:xOff1 context:cx];
    }

    if (nil != _imageOfPreviousFrame) {
      CGImageRelease(_imageOfPreviousFrame);
    }
    _imageOfPreviousFrame = CGBitmapContextCreateImage(cx);

    _lastTick = [NSDate timeIntervalSinceReferenceDate];
  }
}

@end
