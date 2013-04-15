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

#import "AppDelegate.h"

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
#import "PHFlowerAnimation.h"
#import "PHDaftPixelAnimation.h"
#import "PHRainbowHeartAnimation.h"
#import "PHTronAnimation.h"
#import "PHMtFujiAnimation.h"
#import "PHLinesAnimation.h"
#import "PHTetrisAnimation.h"
#import "PHSpiralingSquareAnimation.h"
#import "PHSpectrumLinesAnimation.h"

// Filters
#import "PHBoxBlurFilter.h"
#import "PHDiscBlurFilter.h"
#import "PHDotScreenFilter.h"
#import "PHDrosteFilter.h"
#import "PHEdgesFilter.h"
#import "PHEdgeWorkFilter.h"
#import "PHEightfoldReflectedTileFilter.h"
#import "PHExposureAdjustFilter.h"
#import "PHFalseColorFilter.h"
#import "PHHoleDistortionFilter.h"

#import "PHCompositeAnimation.h"

NSString* const PHAnimationCategorySprites = @"Sprites";
NSString* const PHAnimationCategoryFilters = @"Filters";
NSString* const PHAnimationCategoryPipes = @"Pipes";
NSString* const PHAnimationCategoryPixelHeart = @"Pixel Heart";
NSString* const PHAnimationCategoryShapes = @"Shapes";
NSString* const PHAnimationCategoryTrippy = @"Trippy";

static NSString* const kDefiningPropertiesKey = @"kDefiningPropertiesKey";

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

    _systemState = PHApp().animationDriver;
  }
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  PHAnimation* animation = [[self.class allocWithZone:zone] init];
  animation->_systemState = _systemState;
  return animation;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  id definingProperties = [self definingProperties];
  if (nil != definingProperties) {
    [coder encodeObject:definingProperties forKey:kDefiningPropertiesKey];
  }
}

- (id)initWithCoder:(NSCoder *)decoder {
  if ((self = [self init])) {
    [self setDefiningProperties:[decoder decodeObjectForKey:kDefiningPropertiesKey]];
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  // No-op
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  // No-op
}

- (NSTimeInterval)secondsSinceLastTick {
  if (self.animationTick.hardwareState.playing) {
    NSTimeInterval secondsSinceLastTick = (_lastTick > 0) ? ([NSDate timeIntervalSinceReferenceDate] - _lastTick) : 0;
    return secondsSinceLastTick * self.animationTick.hardwareState.volume * 2;
  } else {
    return 0;
  }
}

- (void)bitmapWillStartRendering {
  if (nil == self.systemState) {
    NSLog(@"Animation %@ has no system state!", self.className);
  }

  if (self.systemState.unifiedSpectrum) {
    [_bassDegrader tickWithPeak:self.systemState.subBassAmplitude];
    [_hihatDegrader tickWithPeak:self.systemState.hihatAmplitude];
    [_vocalDegrader tickWithPeak:self.systemState.vocalAmplitude];
    [_snareDegrader tickWithPeak:self.systemState.snareAmplitude];
  }
}

- (void)bitmapDidFinishRendering {
  _lastTick = [NSDate timeIntervalSinceReferenceDate];
}

+ (NSArray *)allAnimations {
  NSArray* animations =
  // Row 1
  @[
    // Pipes
    [PHResetAnimation animation],
    [PHRotationAnimation animationWithDirection:1],
    [PHRotationAnimation animationWithDirection:0],
    [PHRotationAnimation animationWithDirection:-1],
    [PHMirrorAnimation animationWithType:PHMirrorAnimationTypeLeft],
    [PHMirrorAnimation animationWithType:PHMirrorAnimationTypeRight],
    [PHMirrorAnimation animationWithType:PHMirrorAnimationTypeTop],
    [PHMirrorAnimation animationWithType:PHMirrorAnimationTypeBottom],

    // Filters (commented out ones don't work)
    [PHBoxBlurFilter animation],
    [PHDiscBlurFilter animation],
    [PHDotScreenFilter animation],
    [PHDrosteFilter animation],
    [PHEdgesFilter animation],
//    [PHEdgeWorkFilter animation],
    [PHEightfoldReflectedTileFilter animation],
    [PHExposureAdjustFilter animation],
    [PHFalseColorFilter animation],
    [PHHoleDistortionFilter animation],

    // Animations
    [PHPixelHeartAnimation animation],
    [PHRainbowHeartAnimation animation],
    [PHGifAnimation animation],
    [PHCombAnimation animation],
    [PHMovingSawAnimation animation],
    [PHBassShooterAnimation animation],
    [PHPixelRainAnimation animation],
    [PHRipplesAnimation animationStationary],
    [PHRipplesAnimation animation],
    [PHFlyingRectAnimation animation],
    [PHFlowerAnimation animationWithReactiveCenter:YES],
    [PHFlowerAnimation animationWithReactiveCenter:NO],
    [PHLinesAnimation animation],
    [PHBassPlate animation],
    [PHSpiralingSquareAnimation animation],
    [PHSpectrumLinesAnimation animation],
    [PHFlyingFireballAnimation animation],

    // Sprites
    [PHMegamanAnimation animation],
    [PHPikachuEmotingAnimation animation],
    [PHAdventureTimeAnimation animation],
    [PHSophJoyAnimation animation],
    [PHNyanCatAnimation animation],

    // Games
    [PHTronAnimation animation],
    ];

  // Obsolete animations.
  //[PHDJAnimation animation],
  //[PHTetrisAnimation animation],
  //[PHMtFujiAnimation animation],
  //[PHCountdownAnimation animation],
  //[PHSineWaveAnimation animation],
  //[PHDaftPixelAnimation animation],
  //[PHSpectrumViewerAnimation animation],
  //[PHFireworksAnimation animation],
  //[PHPsychadelicBackgroundAnimation animation],
  //[PHLevelsHorizAnimation animation],
  //[PHGameOfLifeAnimation animation],
  //[PHSimpleMoteAnimation animation],
  //[PHTunnelGameAnimation animation],

  animations =
  [animations arrayByAddingObjectsFromArray:@[
   [PHCompositeAnimation animationWithLayers:@[
    [PHRotationAnimation animationWithDirection:1],
    [PHPixelRainAnimation animation],
    [PHResetAnimation animation],
    [PHMirrorAnimation animationWithType:PHMirrorAnimationTypeTop],
    [PHFlyingFireballAnimation animation]]
                                        name:@"Mirrored Streamers"],

   [PHCompositeAnimation animationWithLayers:@[
    [PHFlowerAnimation animation],
    [PHPixelHeartAnimation animation]]
                                        name:@"Flowered Pixel Heart"],

   [PHCompositeAnimation animationWithLayers:@[
    [PHFlowerAnimation animation],
    [PHMirrorAnimation animationWithType:PHMirrorAnimationTypeTop],
    [PHMirrorAnimation animationWithType:PHMirrorAnimationTypeLeft],
    [PHResetAnimation animation],
    [PHPixelHeartAnimation animation]]
                                        name:@"Kaleidescope Heart"],

   [PHCompositeAnimation animationWithLayers:@[
    [PHBassPlate animation],
    [PHFlyingFireballAnimation animation],
    [PHMirrorAnimation animationWithType:PHMirrorAnimationTypeLeft],
    [PHPixelHeartAnimation animation]]
                                        name:@"Trippy Heart"],

   [PHCompositeAnimation animationWithLayers:@[
    [PHRotationAnimation animationWithDirection:1],
    [PHLinesAnimation animation],
    [PHResetAnimation animation],
    [PHMirrorAnimation animationWithType:PHMirrorAnimationTypeTop],
    [PHPixelHeartAnimation animation]]
                                        name:@"Energy Heart"],

   ]];

  if (nil != sAdditionalAnimationBlock) {
    animations = [animations arrayByAddingObjectsFromArray:sAdditionalAnimationBlock()];
  }

  return animations;
}

+ (NSArray *)allCategories {
  return @[
    PHAnimationCategorySprites,
    PHAnimationCategoryPipes,
    PHAnimationCategoryFilters,
    PHAnimationCategoryPixelHeart,
    PHAnimationCategoryShapes,
    PHAnimationCategoryTrippy
  ];
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

- (NSArray *)categories {
  return nil;
}

@end
