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

#import "PHSophJoyAnimation.h"

static const NSTimeInterval kTimeUntilSurprised = 3;
static const CGFloat kMinimumBass = 0.5;
static const CGFloat kMinimumTimeDoingAnimation = 1;
static const CGFloat kMinimumEnergyForExcite = 0.5;

@implementation PHSophJoyAnimation {
  PHSpritesheet* _spritesheet;
  PHSpriteAnimation* _idleAnimation;
  PHSpriteAnimation* _shockedAnimation;
  PHSpriteAnimation* _jumpAnimation;
  PHSpriteAnimation* _danceAnimation;

  PHSpriteAnimation* _activeAnimation;

  BOOL _hasBeenLulling;
  NSTimeInterval _surprisedTime;
  NSTimeInterval _lastAnimationSwitchTime;
  CGFloat _hihatAbsorber;
  CGFloat _vocalAbsorber;
}

- (id)init {
  if ((self = [super init])) {
    _spritesheet = [[PHSpritesheet alloc] initWithName:@"sophjoy" spriteSize:CGSizeMake(48, 32)];

    _idleAnimation = [[PHSpriteAnimation alloc] initWithSpritesheet:_spritesheet];
    [_idleAnimation addFrameAtX:0 y:0 duration:0.5];
    [_idleAnimation addFrameAtX:1 y:0 duration:0.5];
    [_idleAnimation addStillFrameAtX:2 y:0];

    _shockedAnimation = [[PHSpriteAnimation alloc] initWithSpritesheet:_spritesheet];
    [_shockedAnimation addFrameAtX:3 y:0 duration:0.3];
    [_shockedAnimation addFrameAtX:0 y:1 duration:0.4];
    [_shockedAnimation addStillFrameAtX:0 y:1];

    _jumpAnimation = [[PHSpriteAnimation alloc] initWithSpritesheet:_spritesheet];
    [_jumpAnimation addFrameAtX:1 y:1 duration:0.2];
    [_jumpAnimation addFrameAtX:2 y:1 duration:0.2];
    [_jumpAnimation addFrameAtX:2 y:1 duration:0];
    [_jumpAnimation addFrameAtX:3 y:1 duration:0.2];
    [_jumpAnimation addFrameAtX:0 y:2 duration:0.2];
    [_jumpAnimation addFrameAtX:1 y:2 duration:0.2];
    _jumpAnimation.leftBoundary = 1;

    _danceAnimation = [[PHSpriteAnimation alloc] initWithSpritesheet:_spritesheet];
    [_danceAnimation addStillFrameAtX:3 y:2];
    [_danceAnimation addFrameAtX:2 y:2 duration:0.2];
    [_danceAnimation addFrameAtX:3 y:2 duration:0.2];

    _activeAnimation = _idleAnimation;
    _lastAnimationSwitchTime = [NSDate timeIntervalSinceReferenceDate];
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  _hihatAbsorber = _hihatAbsorber * 0.99 + self.driver.hihatAmplitude * 0.01;
  _vocalAbsorber = _vocalAbsorber * 0.99 + self.driver.vocalAmplitude * 0.01;

  BOOL canSwitchAnimations = NO;
  if (_idleAnimation == _activeAnimation
      || _shockedAnimation == _activeAnimation) {
    canSwitchAnimations = _activeAnimation.isCurrentFrameStill;

  } else if ([NSDate timeIntervalSinceReferenceDate] - _lastAnimationSwitchTime >= kMinimumTimeDoingAnimation) {
    if (_jumpAnimation == _activeAnimation) {
      canSwitchAnimations = _activeAnimation.currentFrameIndex == 2;

    } else {
      canSwitchAnimations = _activeAnimation.isCurrentFrameStill;
    }
  }

  if (!_hasBeenLulling && self.bassDegrader.value < kMinimumBass) {
    _hasBeenLulling = YES;
  }

  if (canSwitchAnimations) {
    PHSpriteAnimation* previousAnimation = _activeAnimation;

    if (_activeAnimation == _idleAnimation) {
      if (_hasBeenLulling && self.bassDegrader.value > kMinimumBass) {
        // Bass drop, surprise!
        _hasBeenLulling = NO;
        _activeAnimation = _shockedAnimation;
        [_shockedAnimation setCurrentFrameIndex:0];
        _surprisedTime = [NSDate timeIntervalSinceReferenceDate] + kTimeUntilSurprised;
      }

      // else wait until a bass drop...

    } else {
      CGFloat totalEnergy = _hihatAbsorber + _vocalAbsorber;
      if ([NSDate timeIntervalSinceReferenceDate] >= _surprisedTime
          && _hasBeenLulling
          && self.bassDegrader.value > kMinimumBass) {
        _hasBeenLulling = NO;

        _activeAnimation = _shockedAnimation;
        [_shockedAnimation setCurrentFrameIndex:0];
        _surprisedTime = [NSDate timeIntervalSinceReferenceDate] + kTimeUntilSurprised;

      } else if ([NSDate timeIntervalSinceReferenceDate] >= _surprisedTime
                 && totalEnergy < kMinimumEnergyForExcite) {
        _activeAnimation = _idleAnimation;

      } else if (totalEnergy >= kMinimumEnergyForExcite) {
        // Pretty fucking excited!
        _activeAnimation = _jumpAnimation;
        [_activeAnimation advanceToNextAnimation];

        if (_hasBeenLulling && self.bassDegrader.value > kMinimumBass) {
          _surprisedTime = [NSDate timeIntervalSinceReferenceDate] + kTimeUntilSurprised;
          _hasBeenLulling = NO;
        }

      } else {
        // Havin' fun.
        _activeAnimation = _danceAnimation;
        if (_hasBeenLulling && self.bassDegrader.value > kMinimumBass) {
          [_activeAnimation setCurrentFrameIndex:1];
          _hasBeenLulling = NO;

          _surprisedTime = [NSDate timeIntervalSinceReferenceDate] + kTimeUntilSurprised;

        } else {
          [_activeAnimation setCurrentFrameIndex:0];
        }
      }
    }

    if (previousAnimation != _activeAnimation) {
      _lastAnimationSwitchTime = [NSDate timeIntervalSinceReferenceDate];
    }
  }

  CGImageRef imageRef = [_activeAnimation imageRefAtCurrentTick];
  CGSize sophjoySize = _spritesheet.spriteSize;
  CGContextDrawImage(cx, CGRectMake(0, 0, sophjoySize.width, sophjoySize.height), imageRef);
  CGImageRelease(imageRef);
}

- (NSString *)tooltipName {
  return @"sophjoy";
}

@end
