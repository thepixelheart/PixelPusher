//
// Copyright 2012 Jeff Verkoeyen, Greg Marra
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

#import "PHNyanCatAnimation.h"

#define NHISTOGRAMS 6
#define TICKEVERY 6
#define TICKMULTIPLIER 3 // how much faster do rainbows run than oscillate?
#define VOLUME_THRESHOLD 0.1

static const NSTimeInterval kMinimumAnimationChangeInterval = 1;
static const NSTimeInterval kMinimumDelayBetweenHits = 0.1;
static const NSTimeInterval kTimeUntilSleeping = 4;

@implementation PHNyanCatAnimation {
    CGFloat _histograms[48*NHISTOGRAMS];
    
    NSInteger _ticks;

  PHSpritesheet* _nyancatSpritesheet;

  PHSpriteAnimation* _idleAnimation;
  PHSpriteAnimation* _runningAnimation;

  PHSpriteAnimation* _activeAnimation;
  NSTimeInterval _nextAllowedAnimationChangeTime;
  NSTimeInterval _nextSleepTime;

  CGFloat _hihatAbsorber;
  CGFloat _vocalAbsorber;
  BOOL _previewing;
}

- (id)init {
    if ((self = [super init])) {
        _ticks = 0;
        
        memset(_histograms, 0, sizeof(CGFloat) * 48 * NHISTOGRAMS);

      _nyancatSpritesheet = [[PHSpritesheet alloc] initWithName:@"nyancat" spriteSize:CGSizeMake(48, 32)];

      _idleAnimation = [[PHSpriteAnimation alloc] initWithSpritesheet:_nyancatSpritesheet];
      [_idleAnimation addStillFrameAtX:6 y:0];
      _idleAnimation.repeats = YES;
      _idleAnimation.bounces = NO;
      _idleAnimation.rightBoundary = 1;

      _runningAnimation = [[PHSpriteAnimation alloc] initWithSpritesheet:_nyancatSpritesheet];
      [_runningAnimation addFrameAtX:5 y:0 duration:kMinimumDelayBetweenHits];
      [_runningAnimation addFrameAtX:4 y:0 duration:kMinimumDelayBetweenHits];
      [_runningAnimation addFrameAtX:3 y:0 duration:kMinimumDelayBetweenHits];
      [_runningAnimation addFrameAtX:2 y:0 duration:kMinimumDelayBetweenHits];
      [_runningAnimation addFrameAtX:1 y:0 duration:kMinimumDelayBetweenHits];
      [_runningAnimation addFrameAtX:0 y:0 duration:kMinimumDelayBetweenHits];
      _runningAnimation.repeats = YES;
      _runningAnimation.bounces = NO;

      _activeAnimation = _idleAnimation;
    }
    return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  NSInteger tailHeight = kWallHeight / 13;

  NSColor* nyanRed = [NSColor colorWithDeviceRed:1 green:0 blue:0 alpha:1];
  NSColor* nyanOrange = [NSColor colorWithDeviceRed:1 green:0.6 blue:0 alpha:1];
  NSColor* nyanYellow = [NSColor colorWithDeviceRed:1 green:1 blue:0 alpha:1];
  NSColor* nyanGreen = [NSColor colorWithDeviceRed:0.2 green:1 blue:0 alpha:1];
  NSColor* nyanBlue = [NSColor colorWithDeviceRed:0 green:0.6 blue:1 alpha:1];
  NSColor* nyanPurple = [NSColor colorWithDeviceRed:0.4 green:0.2 blue:1 alpha:1];

  NSColor* color = nil;
  CGFloat amplitude = 0;

  for (NSInteger ix = 0; ix < NHISTOGRAMS; ++ix) {
    if (ix == 0) {
      color = nyanRed;
      amplitude = self.bassDegrader.value;
    } else if (ix == 1) {
      color = nyanOrange;
      amplitude = self.hihatDegrader.value;
    } else if (ix == 2) {
      color = nyanYellow;
      amplitude = self.vocalDegrader.value;
    } else if (ix == 3) {
      color = nyanGreen;
      amplitude = self.snareDegrader.value;
    } else if (ix == 4) {
      color = nyanBlue;
      amplitude = self.bassDegrader.value;
    } else if (ix == 5) {
      color = nyanPurple;
      amplitude = self.hihatDegrader.value;
    }

    // Shift all values back.
    for (NSInteger col = 0; col < kWallWidth - 1; ++col) {
      _histograms[ix * 48 + col] = _histograms[ix * 48 + col + 1];
    }
    _histograms[ix * 48 + 47] = amplitude;

    for (NSInteger col = kWallWidth / 2; col < kWallWidth; ++col) {

      NSInteger offset = (((col + (_ticks / TICKMULTIPLIER)) % (TICKEVERY * 2)) > TICKEVERY) ? 1 : 0;
      CGFloat val = _histograms[col + ix * 48] * 0.8 + 0.2;
      CGContextSetFillColorWithColor(cx, [color colorWithAlphaComponent: val].CGColor);
      CGRect line = CGRectMake(col - (kWallWidth - 18), tailHeight * ix + 11 + offset, 1, tailHeight);
      CGContextFillRect(cx, line);
    }
  };

  _ticks++;
  _ticks = _ticks % (TICKEVERY * TICKMULTIPLIER * 2);

  _hihatAbsorber = _hihatAbsorber * 0.99 + self.driver.hihatAmplitude * 0.01;
  _vocalAbsorber = _vocalAbsorber * 0.99 + self.driver.vocalAmplitude * 0.01;

  if (!_previewing
      && self.driver.hihatAmplitude < VOLUME_THRESHOLD &&
      self.driver.subBassAmplitude < VOLUME_THRESHOLD &&
      self.driver.vocalAmplitude < VOLUME_THRESHOLD &&
      self.driver.snareAmplitude < VOLUME_THRESHOLD) {
    _activeAnimation = _idleAnimation;
  } else if (_previewing
             || self.driver.hihatAmplitude > 2 * VOLUME_THRESHOLD ||
             self.driver.subBassAmplitude > 2 * VOLUME_THRESHOLD ||
             self.driver.vocalAmplitude > 2 * VOLUME_THRESHOLD ||
             self.driver.snareAmplitude > 2 * VOLUME_THRESHOLD) {
    _activeAnimation = _runningAnimation;
  }

  CGSize nyancatSize = _nyancatSpritesheet.spriteSize;

  CGImageRef imageRef = nil;
  imageRef = [_activeAnimation imageRefAtCurrentTick];
  CGContextDrawImage(cx, CGRectMake(0, 0, nyancatSize.width, nyancatSize.height), imageRef);

  CGImageRelease(imageRef);
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  _previewing = YES;
  [_runningAnimation setCurrentFrameIndex:2];
  [self renderBitmapInContext:cx size:size];
  _previewing = NO;
}

- (NSString *)tooltipName {
  return @"Nyan Cat";
}

- (NSArray *)categories {
  return @[
    PHAnimationCategorySprites
  ];
}

@end
