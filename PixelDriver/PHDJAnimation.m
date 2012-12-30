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

#import "PHDJAnimation.h"

typedef enum {
  PHDJAnimationStateDelayStart,
  PHDJAnimationStateFadeInBackground,
  PHDJAnimationStateFadeInSilhouettes,
  PHDJAnimationStateFadeInCharacters,
  PHDJAnimationStatePauseBeforeWalking,
  PHDJAnimationStateWalkDown,
  PHDJAnimationStateStandBehindTable,

  PHDJAnimationState_Count
} PHDJAnimationState;

NSTimeInterval sDurations[PHDJAnimationState_Count] = {
  0.4, // Delay start
  3,   // Fade in bg
  1,   // Fade in silhouettes
  3,   // Fade in characters
  0.2, // Pause before walking
  2,   // Walk down
  1,   // Stand behind table
};

@implementation PHDJAnimation {
  PHSpritesheet* _jeffSpritesheet;
  PHSpritesheet* _antonSpritesheet;
  
  PHSpritesheet* _tableSpritesheet;
  PHSpritesheet* _surfaceSpritesheet;
  PHSpritesheet* _recordSpritesheet;
  PHSpritesheet* _launchpadSpritesheet;

  PHSpriteAnimation* _jeffWalkingAnimation;
  PHSpriteAnimation* _antonWalkingAnimation;

  PHSpriteAnimation* _jeffWavingAnimation;
  PHSpriteAnimation* _antonWavingAnimation;

  PHDJAnimationState _state;
  NSTimeInterval _nextStateChangeTick;
}

- (id)init {
  if ((self = [super init])) {
    _state = PHDJAnimationStateDelayStart;

    _jeffSpritesheet = [[PHSpritesheet alloc] initWithName:@"jeff" spriteSize:CGSizeMake(16, 24)];
    _antonSpritesheet = [[PHSpritesheet alloc] initWithName:@"anton" spriteSize:CGSizeMake(16, 24)];
    _tableSpritesheet = [[PHSpritesheet alloc] initWithName:@"table" spriteSize:CGSizeMake(48, 20)];
    _surfaceSpritesheet = [[PHSpritesheet alloc] initWithName:@"surface" spriteSize:CGSizeMake(22, 10)];
    _recordSpritesheet = [[PHSpritesheet alloc] initWithName:@"record" spriteSize:CGSizeMake(9, 7)];
    _launchpadSpritesheet = [[PHSpritesheet alloc] initWithName:@"launchpad" spriteSize:CGSizeMake(10, 7)];

    _jeffWalkingAnimation = [self walkingAnimationWithSpritesheet:_jeffSpritesheet];
    _antonWalkingAnimation = [self walkingAnimationWithSpritesheet:_antonSpritesheet];

    _jeffWavingAnimation = [self wavingAnimationWithSpritesheet:_jeffSpritesheet];
    _antonWavingAnimation = [self wavingAnimationWithSpritesheet:_antonSpritesheet];
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  if (0 == _nextStateChangeTick) {
    _nextStateChangeTick = [NSDate timeIntervalSinceReferenceDate] + sDurations[_state];
  }
  if ([NSDate timeIntervalSinceReferenceDate] >= _nextStateChangeTick
      && _state < PHDJAnimationState_Count - 1) {
    _state++;
    _nextStateChangeTick = [NSDate timeIntervalSinceReferenceDate] + sDurations[_state];
  }
  if (_state == PHDJAnimationStateDelayStart) {
    return;
  }

  CGFloat t = MAX(0, MIN(1, 1 - (_nextStateChangeTick - [NSDate timeIntervalSinceReferenceDate]) / sDurations[_state]));
  CGFloat tinout = PHEaseInEaseOut(t);

  if (_state == PHDJAnimationStateFadeInBackground) {
    CGContextSetRGBFillColor(cx, tinout, tinout, tinout, 1);

  } else if (_state <= PHDJAnimationStatePauseBeforeWalking) {
    CGContextSetRGBFillColor(cx, 1, 1, 1, 1);

  } else if (_state == PHDJAnimationStateWalkDown) {
    CGContextSetRGBFillColor(cx, 1 - tinout, 1 - tinout, 1 - tinout, 1);
  }

  if (_state <= PHDJAnimationStateWalkDown) {
    CGContextFillRect(cx, CGRectMake(0, 0, size.width, size.height));
  }

  const CGSize kJeffSize = _jeffSpritesheet.spriteSize;
  const CGSize kAntonSize = _jeffSpritesheet.spriteSize;
  const CGFloat kStartingSpriteOffsetY = -5;
  const CGFloat kFinalSpriteOffsetY = 1;
  CGFloat spriteInsetX = 4;
  CGFloat spriteOffsetY = kStartingSpriteOffsetY;

  CGImageRef jeffImageRef = nil;
  CGImageRef antonImageRef = nil;

  if (_state >= PHDJAnimationStateFadeInSilhouettes
      && _state < PHDJAnimationStateWalkDown) {
    jeffImageRef = [_jeffSpritesheet imageAtX:2 y:0];
    antonImageRef = [_antonSpritesheet imageAtX:2 y:0];

  } else if (_state == PHDJAnimationStateWalkDown) {
    jeffImageRef = [_jeffWalkingAnimation imageRefAtCurrentTick];
    antonImageRef = [_antonWalkingAnimation imageRefAtCurrentTick];

    spriteOffsetY = kStartingSpriteOffsetY + t * (kFinalSpriteOffsetY - kStartingSpriteOffsetY);

  } else if (_state >= PHDJAnimationStateStandBehindTable) {
    jeffImageRef = [_jeffSpritesheet imageAtX:2 y:0];
    antonImageRef = [_antonSpritesheet imageAtX:2 y:0];
    spriteOffsetY = kFinalSpriteOffsetY;
  }

  CGPoint jeffPos = CGPointMake(spriteInsetX, spriteOffsetY);
  CGPoint antonPos = CGPointMake(size.width - kAntonSize.width - spriteInsetX, spriteOffsetY);

  // Draw the silhouettes
  if (_state >= PHDJAnimationStateFadeInSilhouettes && _state <= PHDJAnimationStateFadeInCharacters) {
    if (_state == PHDJAnimationStateFadeInSilhouettes) {
      CGContextSetBlendMode(cx, kCGBlendModeXOR);
      CGContextSetAlpha(cx, t * 0.5);
    } else {
      CGContextSetBlendMode(cx, kCGBlendModeXOR);
      CGContextSetAlpha(cx, 0.5);
    }

    if (jeffImageRef) {
      CGContextDrawImage(cx, CGRectMake(jeffPos.x, jeffPos.y, kJeffSize.width, kJeffSize.height), jeffImageRef);
    }
    if (antonImageRef) {
      CGContextDrawImage(cx, CGRectMake(antonPos.x, antonPos.y, kAntonSize.width, kAntonSize.height), antonImageRef);
    }
  }

  // Draw the colored sprites.
  if (_state >= PHDJAnimationStateFadeInCharacters) {
    CGContextSetBlendMode(cx, kCGBlendModeNormal);
    if (_state == PHDJAnimationStateFadeInCharacters) {
      CGContextSetAlpha(cx, PHEaseIn(t));
    } else {
      CGContextSetAlpha(cx, 1);
    }

    if (jeffImageRef) {
      CGContextDrawImage(cx, CGRectMake(jeffPos.x, floorf(jeffPos.y), kJeffSize.width, kJeffSize.height), jeffImageRef);
    }
    if (antonImageRef) {
      CGContextDrawImage(cx, CGRectMake(antonPos.x, floorf(antonPos.y), kAntonSize.width, kAntonSize.height), antonImageRef);
    }
  }

  // Draw the table.
  if (_state >= PHDJAnimationStateWalkDown) {
    CGFloat kTableFinalDelta = -14;
    CGFloat tableOffsetY;
    if (_state == PHDJAnimationStateWalkDown) {
      tableOffsetY = t * kTableFinalDelta;
    } else {
      tableOffsetY = kTableFinalDelta;
    }

    // Table
    CGImageRef imageRef = [_tableSpritesheet imageAtX:0 y:0];
    CGSize spriteSize = _tableSpritesheet.spriteSize;
    CGContextDrawImage(cx, CGRectMake(0, size.height + tableOffsetY,
                                      spriteSize.width, spriteSize.height), imageRef);
    CGImageRelease(imageRef);

    // Surfaces
    const CGFloat kSurfaceInsetX = 1;
    const CGFloat kSurfaceOffsetY = 1;
    imageRef = [_surfaceSpritesheet imageAtX:0 y:0];
    spriteSize = _surfaceSpritesheet.spriteSize;
    CGContextDrawImage(cx, CGRectMake(kSurfaceInsetX,
                                      size.height + tableOffsetY + kSurfaceOffsetY,
                                      spriteSize.width, spriteSize.height), imageRef);
    CGContextDrawImage(cx, CGRectMake(size.width - spriteSize.width - kSurfaceInsetX,
                                      size.height + tableOffsetY + kSurfaceOffsetY,
                                      spriteSize.width, spriteSize.height), imageRef);
    CGImageRelease(imageRef);

    // Launchpad
    const CGFloat kLaunchpadInsetX = 6;
    const CGFloat kLaunchpadOffsetY = 1;
    imageRef = [_launchpadSpritesheet imageAtX:0 y:0];
    spriteSize = _launchpadSpritesheet.spriteSize;
    CGContextDrawImage(cx, CGRectMake(kSurfaceInsetX + kLaunchpadInsetX,
                                      size.height + tableOffsetY + kSurfaceOffsetY + kLaunchpadOffsetY,
                                      spriteSize.width, spriteSize.height), imageRef);
    CGImageRelease(imageRef);

    // Turntables
    const CGFloat kTurntableInsetX = 1;
    const CGFloat kTurntableOffsetY = 1;
    const CGFloat kTurntableSpacingX = 2;
    imageRef = [_recordSpritesheet imageAtX:0 y:0];
    spriteSize = _recordSpritesheet.spriteSize;
    CGContextDrawImage(cx, CGRectMake(size.width - spriteSize.width - kSurfaceInsetX - kTurntableInsetX,
                                      size.height + tableOffsetY + kSurfaceOffsetY + kTurntableOffsetY,
                                      spriteSize.width, spriteSize.height), imageRef);
    CGContextDrawImage(cx, CGRectMake(size.width - spriteSize.width * 2 - kSurfaceInsetX - kTurntableInsetX - kTurntableSpacingX,
                                      size.height + tableOffsetY + kSurfaceOffsetY + kTurntableOffsetY,
                                      spriteSize.width, spriteSize.height), imageRef);
    CGImageRelease(imageRef);
  }

  if (jeffImageRef) {
    CGImageRelease(jeffImageRef);
  }
  if (antonImageRef) {
    CGImageRelease(antonImageRef);
  }
}

- (PHSpriteAnimation *)walkingAnimationWithSpritesheet:(PHSpritesheet *)spritesheet {
  PHSpriteAnimation* animation = [[PHSpriteAnimation alloc] initWithSpritesheet:spritesheet];
  [animation addFrameAtX:2 y:0 duration:0.2];
  [animation addFrameAtX:0 y:1 duration:0.2];
  [animation addFrameAtX:2 y:0 duration:0.2];
  [animation addFrameAtX:1 y:1 duration:0.2];
  animation.repeats = YES;
  animation.bounces = NO;
  return animation;
}

- (PHSpriteAnimation *)wavingAnimationWithSpritesheet:(PHSpritesheet *)spritesheet {
  PHSpriteAnimation* animation = [[PHSpriteAnimation alloc] initWithSpritesheet:spritesheet];
  [animation addFrameAtX:0 y:0 duration:0.4];
  [animation addFrameAtX:1 y:0 duration:0.4];
  animation.repeats = YES;
  animation.bounces = NO;
  return animation;
}

- (NSString *)tooltipName {
  return @"Anton & Jeff";
}

@end
