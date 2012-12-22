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

#import "PHPikachuEmotingAnimation.h"

static const NSTimeInterval kMinimumAnimationChangeInterval = 1;
static const NSTimeInterval kMinimumDelayBetweenHits = 0.1;
static const NSTimeInterval kTimeUntilSleeping = 4;

@implementation PHPikachuEmotingAnimation {
  PHSpritesheet* _pikachuSpritesheet;

  PHSpriteAnimation* _idleAnimation;
  PHSpriteAnimation* _contentAnimation;
  PHSpriteAnimation* _happyAnimation;
  PHSpriteAnimation* _ecstaticAnimation;
  PHSpriteAnimation* _sleepingAnimation;

  PHSpriteAnimation* _activeAnimation;
  NSTimeInterval _nextAllowedAnimationChangeTime;
  NSTimeInterval _nextSleepTime;

  PHDegrader* _bassDegrader;
  CGFloat _hihatAbsorber;
  CGFloat _vocalAbsorber;
  BOOL _hasBeenLulling;
  BOOL _isFrightened;
}

- (id)init {
  if ((self = [super init])) {
    _bassDegrader = [[PHDegrader alloc] init];

    _pikachuSpritesheet = [[PHSpritesheet alloc] initWithName:@"pikachu-emote" spriteSize:CGSizeMake(48, 32)];

    _idleAnimation = [[PHSpriteAnimation alloc] initWithSpritesheet:_pikachuSpritesheet];
    [_idleAnimation addStillFrameAtX:0 y:0];
    [_idleAnimation addFrameAtX:1 y:0 duration:0.1];
    [_idleAnimation addFrameAtX:0 y:0 duration:kMinimumDelayBetweenHits];
    _idleAnimation.repeats = YES;
    _idleAnimation.bounces = NO;

    _contentAnimation = [[PHSpriteAnimation alloc] initWithSpritesheet:_pikachuSpritesheet];
    [_contentAnimation addStillFrameAtX:4 y:1];
    [_contentAnimation addFrameAtX:0 y:2 duration:0.1];
    [_contentAnimation addFrameAtX:4 y:1 duration:kMinimumDelayBetweenHits];
    _contentAnimation.repeats = YES;
    _contentAnimation.bounces = NO;

    _happyAnimation = [[PHSpriteAnimation alloc] initWithSpritesheet:_pikachuSpritesheet];
    [_happyAnimation addStillFrameAtX:1 y:1];
    [_happyAnimation addFrameAtX:2 y:1 duration:0.1];
    [_happyAnimation addFrameAtX:3 y:1 duration:0.2];
    [_happyAnimation addFrameAtX:1 y:1 duration:kMinimumDelayBetweenHits];
    _happyAnimation.repeats = YES;
    _happyAnimation.bounces = NO;

    _ecstaticAnimation = [[PHSpriteAnimation alloc] initWithSpritesheet:_pikachuSpritesheet];
    [_ecstaticAnimation addStillFrameAtX:4 y:0];
    [_ecstaticAnimation addFrameAtX:0 y:1 duration:0.1];
    [_ecstaticAnimation addFrameAtX:4 y:0 duration:kMinimumDelayBetweenHits];
    _ecstaticAnimation.repeats = YES;
    _ecstaticAnimation.bounces = NO;

    _sleepingAnimation = [[PHSpriteAnimation alloc] initWithSpritesheet:_pikachuSpritesheet];
    [_sleepingAnimation addFrameAtX:1 y:2 duration:0.9];
    [_sleepingAnimation addFrameAtX:2 y:2 duration:1.1];
    [_sleepingAnimation addFrameAtX:3 y:2 duration:0.2];
    _sleepingAnimation.repeats = YES;
    _sleepingAnimation.bounces = NO;
    _sleepingAnimation.rightBoundary = 1;
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  if (self.driver.spectrum) {
    CGContextSetRGBFillColor(cx, 1, 1, 1, 0.2);
    CGContextFillRect(cx, CGRectMake(0, 0, size.width, size.height));

    [_bassDegrader tickWithPeak:self.driver.subBassAmplitude];
    _hihatAbsorber = _hihatAbsorber * 0.99 + self.driver.hihatAmplitude * 0.01;
    _vocalAbsorber = _vocalAbsorber * 0.99 + self.driver.vocalAmplitude * 0.01;

    _hasBeenLulling = _hasBeenLulling || (self.driver.subBassAmplitude < 0.5);

    if (_activeAnimation.currentFrameIndex == 0 && [NSDate timeIntervalSinceReferenceDate] >= _nextAllowedAnimationChangeTime) {
      PHSpriteAnimation* nextAnimation = _activeAnimation;
      if (_isFrightened && _sleepingAnimation.currentFrameIndex < 2) {
        _isFrightened = NO;
        _nextSleepTime = [NSDate timeIntervalSinceReferenceDate] + kTimeUntilSleeping;
      }
      if (_isFrightened) {
        nextAnimation = _sleepingAnimation;
      } else if (_hihatAbsorber > 0.5 && _vocalAbsorber > 0.5) {
        nextAnimation = _ecstaticAnimation;
      } else if (_hihatAbsorber > 0.3) {
        nextAnimation = _happyAnimation;
      } else if (_vocalAbsorber > 0.3) {
        nextAnimation = _contentAnimation;

        if ([NSDate timeIntervalSinceReferenceDate] >= _nextSleepTime) {
          nextAnimation = _sleepingAnimation;
        }

      } else {
        nextAnimation = _idleAnimation;

        if ([NSDate timeIntervalSinceReferenceDate] >= _nextSleepTime) {
          nextAnimation = _sleepingAnimation;
        }
      }

      if (nextAnimation != _activeAnimation) {
        _activeAnimation = nextAnimation;
        [_activeAnimation setCurrentFrameIndex:0];

        if (_activeAnimation != _sleepingAnimation) {
          _nextAllowedAnimationChangeTime = [NSDate timeIntervalSinceReferenceDate] + kMinimumAnimationChangeInterval;
        }
      }
    }

    if (_hasBeenLulling && self.driver.subBassAmplitude > 0.5) {
      if (!_isFrightened && _activeAnimation == _sleepingAnimation && _sleepingAnimation.currentFrameIndex < 2) {
        [_sleepingAnimation setCurrentFrameIndex:2];
        _isFrightened = YES;
        _nextAllowedAnimationChangeTime = [NSDate timeIntervalSinceReferenceDate] + kMinimumAnimationChangeInterval;

      } else if (_activeAnimation.currentFrameIndex == 0) {
        [_activeAnimation advanceToNextAnimation];
        _nextSleepTime = [NSDate timeIntervalSinceReferenceDate] + kTimeUntilSleeping;
      }
      _hasBeenLulling = NO;
    }

    CGSize size = _pikachuSpritesheet.spriteSize;

    CGImageRef imageRef = nil;
    imageRef = [_activeAnimation imageRefAtCurrentTick];
    if (_isFrightened) {
      CGImageRelease(imageRef);
      imageRef = [_pikachuSpritesheet imageAtX:3 y:2];
    }
    CGContextDrawImage(cx, CGRectMake(0, 0, size.width, size.height), imageRef);

    CGImageRelease(imageRef);

  }
}

@end
