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

#import "PHMegamanAnimation.h"

static const NSTimeInterval kMinimumBlinkInterval = 3;

@implementation PHMegamanAnimation {
  PHSpritesheet* _megamanSpritesheet;
  PHSpritesheet* _tilesSpritesheet;
  PHSpriteAnimation* _runningAnimation;

  CGImageRef _backgroundImageRef;

  CGFloat _backgroundOffset;
  CGFloat _foregroundOffset;
  CGFloat _advance;

  BOOL _isBlinking;
  BOOL _hasBeenLulling;
  NSTimeInterval _lastBlinkTime;
  NSTimeInterval _blinkStartedAtTime;
}

- (void)dealloc {
  CGImageRelease(_backgroundImageRef);
}

- (id)init {
  if ((self = [super init])) {
    _megamanSpritesheet = [[PHSpritesheet alloc] initWithName:@"megaman-nes-blue" spriteSize:CGSizeMake(32, 32)];
    _tilesSpritesheet = [[PHSpritesheet alloc] initWithName:@"megaman-nes-tiles" spriteSize:CGSizeMake(16, 16)];

    _runningAnimation = [[PHSpriteAnimation alloc] initWithSpritesheet:_megamanSpritesheet];
    _runningAnimation.bounces = YES;
    _runningAnimation.repeats = YES;
    [_runningAnimation addFrameAtX:0 y:0 duration:0.12];
    [_runningAnimation addFrameAtX:2 y:0 duration:0.6];
    [_runningAnimation addFrameAtX:3 y:0 duration:0.12];
    [_runningAnimation addFrameAtX:4 y:0 duration:0.12];
    [_runningAnimation addFrameAtX:5 y:0 duration:0.12];
    _runningAnimation.leftBoundary = 2;

    _backgroundImageRef = [_tilesSpritesheet imageAtX:3 y:0];
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  _hasBeenLulling = _hasBeenLulling || (self.driver.hihatAmplitude < 0.3);
  if ([NSDate timeIntervalSinceReferenceDate] - _blinkStartedAtTime > 0.1) {
    _isBlinking = NO;
  }

  CGFloat runningSpeed = self.bassDegrader.value * 3;
  if (runningSpeed < 0.4) {
    runningSpeed = 0;
  }
  NSTimeInterval delta = self.secondsSinceLastTick;
  _advance += delta * runningSpeed;
  _backgroundOffset -= delta * 10 * runningSpeed;
  _foregroundOffset -= delta * 24 * runningSpeed;
  _runningAnimation.animationScale = sqrt(runningSpeed / 3);

  CGContextSetInterpolationQuality(cx, kCGInterpolationDefault);

  CGSize tileSize = _tilesSpritesheet.spriteSize;
  CGRect tileFrame = CGRectMake(0, 0, tileSize.width, tileSize.height);
  CGFloat circularOffset = fmodf(_backgroundOffset, tileSize.width);

  for (NSInteger ix = 0; ix < 4; ++ix) {
    tileFrame.origin.x = circularOffset + ix * tileSize.width;

    for (NSInteger iy = 0; iy < 2; ++iy) {
      tileFrame.origin.y = floorf(iy * tileSize.width - 8);
      CGContextDrawImage(cx, tileFrame, _backgroundImageRef);
    }
  }

  circularOffset = fmodf(_foregroundOffset, tileSize.width);
  tileFrame.origin.y = kWallHeight - 8;
  for (NSInteger ix = 0; ix < 4; ++ix) {
    tileFrame.origin.x = floorf(circularOffset + ix * tileSize.width);

    NSInteger offsetFrame = (NSInteger)fabsf(floorf(_foregroundOffset / tileSize.width)) % 3;
    CGImageRef image = [_tilesSpritesheet imageAtX:(ix + offsetFrame) % 3 y:0];
    CGContextDrawImage(cx, tileFrame, image);
    CGImageRelease(image);
  }

  CGImageRef imageRef = nil;

  if (runningSpeed > 0) {
    imageRef = [_runningAnimation imageRefAtCurrentTick];
    _lastBlinkTime = [NSDate timeIntervalSinceReferenceDate];
  } else {
    if (!_isBlinking && _hasBeenLulling
        && (self.driver.hihatAmplitude > 0.4
            || [NSDate timeIntervalSinceReferenceDate] - _lastBlinkTime > kMinimumBlinkInterval)) {
      _isBlinking = YES;
       _hasBeenLulling = NO;
      _lastBlinkTime = [NSDate timeIntervalSinceReferenceDate] + ((CGFloat)arc4random_uniform(2000)) / 1000;
      _blinkStartedAtTime = [NSDate timeIntervalSinceReferenceDate];
    }
    if (_isBlinking) {
      imageRef = [_megamanSpritesheet imageAtX:1 y:0];
    } else {
      imageRef = [_megamanSpritesheet imageAtX:0 y:0];
    }
    [_runningAnimation setCurrentFrameIndex:0];
  }

  CGSize megamanSize = _megamanSpritesheet.spriteSize;
  CGContextDrawImage(cx, CGRectMake(floorf(sin(_advance / 5) * 10 + 10), -8, megamanSize.width, megamanSize.height), imageRef);

  CGImageRelease(imageRef);
}

- (NSString *)tooltipName {
  return @"Megaman";
}

@end
