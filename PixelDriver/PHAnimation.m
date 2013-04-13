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

// Filters
#import "PHHoleDistortionFilter.h"

#import "PHCompositeAnimation.h"

NSString* const PHAnimationCategorySprites = @"Sprites";
NSString* const PHAnimationCategoryPipes = @"Pipes";
NSString* const PHAnimationCategoryPixelHeart = @"Pixel Heart";
NSString* const PHAnimationCategoryShapes = @"Shapes";
NSString* const PHAnimationCategoryTrippy = @"Trippy";

static NSString* const kDefiningPropertiesKey = @"kDefiningPropertiesKey";

const NSInteger PHInitialAnimationIndex = 3;
static PHAdditionalAnimationBlock sAdditionalAnimationBlock = nil;

@implementation PHAnimationTick
@end

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
  return (_lastTick > 0) ? ([NSDate timeIntervalSinceReferenceDate] - _lastTick) : 0;
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

    [PHBassPlate animation],

    [PHMegamanAnimation animation],
    [PHPikachuEmotingAnimation animation],

    [PHDJAnimation animation],

    [PHHoleDistortionFilter animation],

    // Row 2
    [PHPixelHeartAnimation animation],
    [PHGifAnimation animation],

    [PHSophJoyAnimation animation],
    [PHNyanCatAnimation animation],

    [PHAdventureTimeAnimation animation],

    // Row 3
    [PHCombAnimation animation],
    [PHMovingSawAnimation animation],

    [PHBassShooterAnimation animation],
    [PHCountdownAnimation animation],

    [PHPixelRainAnimation animation],
    [PHFlyingFireballAnimation animation],

    [PHRipplesAnimation animationStationary],
    [PHRipplesAnimation animation],

    // Row 4
    [PHFlyingRectAnimation animation],
    [PHFlowerAnimation animation],

    [PHSineWaveAnimation animation],

    [PHDaftPixelAnimation animation],
  [PHRainbowHeartAnimation animation],

  [PHTronAnimation animation],
    [PHMtFujiAnimation animation],

    [PHLinesAnimation animation],
    [PHTetrisAnimation animation],

    [PHSpiralingSquareAnimation animation],
    ];

  // Obsolete animations.
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
    [PHRotationAnimation animationWithDirection:0],
    [PHMegamanAnimation animation]]
                                        name:@"Rotating Megaman"],

   [PHCompositeAnimation animationWithLayers:@[
    [PHRotationAnimation animationWithDirection:0],
    [PHRainbowHeartAnimation animation]]
                                        name:@"Rotating Rainbow Heart"],

   [PHCompositeAnimation animationWithLayers:@[
    [PHRainbowHeartAnimation animation],
    [PHPikachuEmotingAnimation animation]]
                                        name:@"Heartachu"],

   [PHCompositeAnimation animationWithLayers:@[
    [PHRotationAnimation animationWithDirection:1],
    [PHLinesAnimation animation],
    [PHResetAnimation animation],
    [PHMirrorAnimation animationWithType:PHMirrorAnimationTypeTop],
    [PHPixelHeartAnimation animation]]
                                        name:@"Energy Heart"],

   [PHCompositeAnimation animationWithLayers:@[
    [PHRotationAnimation animationWithDirection:1],
    [PHSpiralingSquareAnimation animation],]
                                        name:@"Rotating Spiral"],

   [PHCompositeAnimation animationWithLayers:@[
    [PHMovingSawAnimation animation],
    [PHHoleDistortionFilter animation]]
                                        name:@"Hole Moving Saw"],

   [PHCompositeAnimation animationWithLayers:@[
    [PHMegamanAnimation animation],
    [PHHoleDistortionFilter animation]]
                                        name:@"Hole Moving Saw"],


   [PHCompositeAnimation animationWithLayers:@[
    [PHFlowerAnimation animation],
    [PHHoleDistortionFilter animation]]
                                        name:@"Hole Moving Saw"],



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
