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

#import "PHAnimation.h"

#import "PHBasicSpectrumAnimation.h"
#import "PHSpectrumViewerAnimation.h"
#import "PHBassPlate.h"
#import "PHFireworksAnimation.h"
#import "PHFlyingFireballAnimation.h"
#import "PHLevelsHorizAnimation.h"
#import "PHResetAnimation.h"
#import "PHNyanCatAnimation.h"
#import "PHMegamanAnimation.h"
#import "PHPikachuEmotingAnimation.h"
#import "PHSineWaveAnimation.h"
#import "PHPsychadelicBackgroundAnimation.h"
#import "PHFlyingRectAnimation.h"
#import "PHPixelHeartAnimation.h"
#import "PHGameOfLifeAnimation.h"
#import "PHRotationAnimation.h"
#import "PHSimpleMoteAnimation.h"
#import "PHTunnelGameAnimation.h"
#import "PHCountdownAnimation.h"
#import "PHRipplesAnimation.h"
#import "PHDJAnimation.h"
#import "PHSophJoyAnimation.h"
#import "PHCombAnimation.h"
#import "PHAdventureTimeAnimation.h"
#import "PHPixelRainAnimation.h"
#import "PHMovingSawAnimation.h"
#import "PHGifAnimation.h"
#import "PHMirrorAnimation.h"
#import "PHBassShooterAnimation.h"

const NSInteger PHInitialAnimationIndex = 3;
static PHAdditionalAnimationBlock sAdditionalAnimationBlock = nil;

@implementation PHAnimation

+ (id)animation {
  return [[self alloc] init];
}

- (id)init {
  if ((self = [super init])) {
    _bassDegrader = [[PHDegrader alloc] init];
    _hihatDegrader = [[PHDegrader alloc] init];
    _vocalDegrader = [[PHDegrader alloc] init];
    _snareDegrader = [[PHDegrader alloc] init];
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  // No-op
}

- (NSTimeInterval)secondsSinceLastTick {
  return (_lastTick > 0) ? ([NSDate timeIntervalSinceReferenceDate] - _lastTick) : 0;
}

- (void)bitmapWillStartRendering {
  if (self.driver.unifiedSpectrum) {
    [_bassDegrader tickWithPeak:self.driver.subBassAmplitude];
    [_hihatDegrader tickWithPeak:self.driver.hihatAmplitude];
    [_vocalDegrader tickWithPeak:self.driver.vocalAmplitude];
    [_snareDegrader tickWithPeak:self.driver.snareAmplitude];
  }
}

- (void)bitmapDidFinishRendering {
  _lastTick = [NSDate timeIntervalSinceReferenceDate];
}

+ (NSArray *)allAnimations {
  NSArray* animations =
  // Row 1
  @[[PHResetAnimation animation],
    [PHPixelHeartAnimation animation],
    
    [PHMegamanAnimation animation],
    [PHPikachuEmotingAnimation animation],

    [PHDJAnimation animation],
    [PHFlyingFireballAnimation animation],

    [PHCombAnimation animation],
    [PHFlyingRectAnimation animation],

    // Row 2
    [PHSineWaveAnimation animation],
    [PHBassPlate animation],

    [PHSophJoyAnimation animation],
    [PHNyanCatAnimation animation],

    [PHRipplesAnimation animationStationary],
    [PHRipplesAnimation animation],

    [PHCountdownAnimation animation],
    [PHAdventureTimeAnimation animation],

    // Row 3
    [PHPixelRainAnimation animation],
    [PHMovingSawAnimation animation],

    [PHGifAnimation animation],
    [PHBassShooterAnimation animation],

    // Pipe animations
    [PHRotationAnimation animationWithDirection:1],
    [PHRotationAnimation animationWithDirection:-1],

    [PHMirrorAnimation animationWithType:PHMirrorAnimationTypeLeft],
    [PHMirrorAnimation animationWithType:PHMirrorAnimationTypeRight],
    [PHMirrorAnimation animationWithType:PHMirrorAnimationTypeTop],
    [PHMirrorAnimation animationWithType:PHMirrorAnimationTypeBottom],

    ];

  // Obsolete animations.
  //[PHSpectrumViewerAnimation animation],
  //[PHFireworksAnimation animation],
  //[PHPsychadelicBackgroundAnimation animation],
  //[PHLevelsHorizAnimation animation],
  //[PHGameOfLifeAnimation animation],
  //[PHSimpleMoteAnimation animation],
  //[PHTunnelGameAnimation animation],

  if (nil != sAdditionalAnimationBlock) {
    animations = [animations arrayByAddingObjectsFromArray:sAdditionalAnimationBlock()];
  }

  return animations;
}

+ (void)setAdditionalAnimationCreator:(PHAdditionalAnimationBlock)block {
  sAdditionalAnimationBlock = [block copy];
}

- (CGPathRef)createQuartzPathFromPath:(NSBezierPath *)bezierPath {
  int i;

  // Need to begin a path here.
  CGPathRef immutablePath = NULL;

  // Then draw the path elements.
  NSInteger numElements = [bezierPath elementCount];
  if (numElements > 0) {
    CGMutablePathRef    path = CGPathCreateMutable();
    NSPoint             points[3];
    BOOL                didClosePath = YES;

    for (i = 0; i < numElements; i++)
    {
      switch ([bezierPath elementAtIndex:i associatedPoints:points])
      {
        case NSMoveToBezierPathElement:
          CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
          break;

        case NSLineToBezierPathElement:
          CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
          didClosePath = NO;
          break;

        case NSCurveToBezierPathElement:
          CGPathAddCurveToPoint(path, NULL, points[0].x, points[0].y,
                                points[1].x, points[1].y,
                                points[2].x, points[2].y);
          didClosePath = NO;
          break;

        case NSClosePathBezierPathElement:
          CGPathCloseSubpath(path);
          didClosePath = YES;
          break;
      }
    }

    // Be sure the path is closed or Quartz may not do valid hit detection.
    if (!didClosePath)
      CGPathCloseSubpath(path);

    immutablePath = CGPathCreateCopy(path);
    CGPathRelease(path);
  }

  return immutablePath;
}

- (NSString *)tooltipName {
  return NSStringFromClass([self class]);
}

- (BOOL)isPipeAnimation {
  return NO;
}

@end
