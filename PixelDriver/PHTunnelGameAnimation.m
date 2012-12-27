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

#import "PHTunnelGameAnimation.h"

#define WORLDOFFSETFROMXY(x, y) (((NSInteger)x) * 4 + (((NSInteger)y) * bytesPerRow))

static const PHPitch kStartingPitch = PHPitchC3;
static const PHPitch kEndingPitch = PHPitchC6;
static const NSTimeInterval kMinimumPitchAge = 0.1;

@implementation PHTunnelGameAnimation {
  CGContextRef _worldContextRef;
  NSTimeInterval _ageOfCurrentPitch;
  PHPitch _currentPitch;
  PHPitch _lockedPitch; // A pitch that's only set after kMinimumPitchAge has been reached.
  CGFloat _floatingCenter;

  CGFloat _colorAdvance;
}

- (void)dealloc {
  if (_worldContextRef) {
    CGContextRelease(_worldContextRef);
  }
}

- (id)init {
  if ((self = [super init])) {
    _worldContextRef = PHCreate8BitBitmapContextWithSize(CGSizeMake(kWallWidth, kWallHeight));
    _floatingCenter = 0.5;
    _lockedPitch = PHPitch_Unknown;
  }
  return self;
}

- (void)tickWorld {
  unsigned char* data = (unsigned char *)CGBitmapContextGetData(_worldContextRef);
  size_t bytesPerRow = CGBitmapContextGetBytesPerRow(_worldContextRef);

  // Move the world back.
  for (NSInteger iy = 0; iy < kWallHeight; ++iy) {
    for (NSInteger ix = 0; ix < kWallWidth - 1; ++ix) {
      NSInteger offset = WORLDOFFSETFROMXY(ix, iy);
      NSInteger nextOffset = WORLDOFFSETFROMXY(ix + 1, iy);

      data[offset + 0] = data[nextOffset + 0];
      data[offset + 1] = data[nextOffset + 1];
      data[offset + 2] = data[nextOffset + 2];
      if (data[nextOffset + 0] == 255
          && data[nextOffset + 1] == 255
          && data[nextOffset + 2] == 255) {
        // Player.
        data[offset + 3] = data[nextOffset + 3] * 0.8;

      } else {
        data[offset + 3] = data[nextOffset + 3];
      }
    }
  }

  // Calculate the pitch.
  if ((self.driver.dominantPitch >= kStartingPitch
       && self.driver.dominantPitch <= kEndingPitch)
      || self.driver.dominantPitch == PHPitch_Unknown) {
    if (self.driver.dominantPitch == _currentPitch) {
      _ageOfCurrentPitch += self.secondsSinceLastTick;
    } else {
      _currentPitch = self.driver.dominantPitch;
      _ageOfCurrentPitch = 0;
    }

    if (_ageOfCurrentPitch >= kMinimumPitchAge
        && _lockedPitch != _currentPitch) {
      _lockedPitch = _currentPitch;
    }
  }

  CGFloat pitchPercentage = 0.5;
  if (_lockedPitch != PHPitch_Unknown) {
    CGFloat offset = (NSInteger)_lockedPitch - (NSInteger)kStartingPitch;
    CGFloat size = kEndingPitch - kStartingPitch;
    pitchPercentage = offset / size;
  }

  _floatingCenter += (pitchPercentage - _floatingCenter) * MIN(1, self.secondsSinceLastTick * 2);

  CGFloat openingSize = MAX(0.3 * (CGFloat)kWallHeight,
                            kWallHeight - self.bassDegrader.value * (CGFloat)kWallHeight * 3 / 4);
  CGFloat openingCenter = _floatingCenter * kWallHeight;
  CGFloat openingTopEdge = MAX(1, openingCenter - openingSize / 2);
  CGFloat openingBottomEdge = openingTopEdge + openingSize;
  if (openingBottomEdge >= kWallHeight - 1) {
    openingBottomEdge = kWallHeight - 1;
    openingTopEdge = openingBottomEdge - openingSize;
  }

  _colorAdvance += self.secondsSinceLastTick / 16;

  // Create the next column.
  for (CGFloat iy = 0; iy < kWallHeight; ++iy) {
    NSInteger alpha;

    if (iy < openingTopEdge + 1
        || iy >= openingBottomEdge) {
      alpha = 255;
    } else {
      alpha = 0;
    }
    NSInteger offset = WORLDOFFSETFROMXY(kWallWidth - 1, iy);
    NSColor* color = [NSColor colorWithDeviceHue:fmodf(_colorAdvance, 1)
                                      saturation:1
                                      brightness:MAX(0.4, self.vocalDegrader.value)
                                           alpha:1];
    CGFloat r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    data[offset + 0] = r * 255;
    data[offset + 1] = g * 255;
    data[offset + 2] = b * 255;
    data[offset + 3] = alpha;
  }

  CGPoint centerPlayerPosition = CGPointMake(kWallWidth / 4, kWallHeight / 2);
  CGFloat movementRadius = kWallWidth / 4;
  for (PHMote* mote in self.driver.motes) {
    CGFloat degrees = mote.joystickDegrees;
    CGFloat radians = degrees * M_PI / 180;
    CGFloat tilt = mote.joystickTilt;

    CGPoint playerPosition;
    playerPosition.x = centerPlayerPosition.x + movementRadius * cosf(radians) * tilt;
    playerPosition.y = centerPlayerPosition.y + movementRadius * sinf(radians) * tilt;

    CGFloat playerRadius = self.vocalDegrader.value * 2 + 1;
    CGRect playerRect = CGRectMake(playerPosition.x - playerRadius,
                                   playerPosition.y - playerRadius,
                                   playerRadius * 2,
                                   playerRadius * 2);
    CGContextSetRGBFillColor(_worldContextRef, 1, 1, 1, 1);
    CGContextFillEllipseInRect(_worldContextRef, playerRect);
  }
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  if (self.driver.unifiedSpectrum) {
    [self tickWorld];

    CGImageRef imageRef = CGBitmapContextCreateImage(_worldContextRef);
    CGContextDrawImage(cx, CGRectMake(0, 0, size.width, size.height), imageRef);
    CGImageRelease(imageRef);
  }
}

@end
