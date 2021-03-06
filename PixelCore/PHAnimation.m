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
#import "PHRotatingSquaresAnimation.h"
#import "PHLaunchpadDemoAnimation.h"
#import "PHPixelLifeAnimation.h"
#import "PHBox2DAnimation.h"
#import "PHDancingManAnimation.h"
#import "PHCornerParticlesAnimation.h"
#import "PHMotionBlurAnimation.h"
#import "PHMaskAnimation.h"
#import "PHPixelTunnelAnimation.h"
#import "PHSoundBoxAnimation.h"
#import "PHFlowyColorsAnimation.h"
#import "PHScreenCaptureAnimation.h"
#import "PHKinectAnimation.h"
#import "PHMandelbrotAnimation.h"
#import "PHStaticAnimation.h"
#import "PHClockAnimation.h"
#import "PHPixelHeartTextAnimation.h"
#import "PHMarioAnimation.h"
#import "PHDoLabAnimation.h"
#import "PHDancingGifsAnimation.h"
#import "PHTrippyTunnelAnimation.h"
#import "PHTwistedAnimation.h"
#import "PHSoundWaveAnimation.h"
#import "PHFlippingSquaresAnimation.h"
#import "PHPositiveStatementsAnimation.h"
#import "PHColorSpliceAnimation.h"
#import "PHRaindropRipplesAnimation.h"

// Filters
#import "PHAffineTileFilter.h"
#import "PHBloomFilter.h"
#import "PHBumpDistortionFilter.h"
#import "PHBoxBlurFilter.h"
#import "PHCheckerboardGeneratorFilter.h"
#import "PHCircleSplashDistortionFilter.h"
#import "PHColorInvertFilter.h"
#import "PHComicFilter.h"
#import "PHDiscBlurFilter.h"
#import "PHDotScreenFilter.h"
#import "PHDrosteFilter.h"
#import "PHEdgesFilter.h"
#import "PHEdgeWorkFilter.h"
#import "PHEightfoldReflectedTileFilter.h"
#import "PHExposureAdjustFilter.h"
#import "PHFalseColorFilter.h"
#import "PHHoleDistortionFilter.h"
#import "PHKaleidoscopeFilter.h"
#import "PHTriangleTileFilter.h"

#import "PHCompositeAnimation.h"

NSString* const PHAnimationCategorySprites = @"Sprites";
NSString* const PHAnimationCategoryFilters = @"Filters";
NSString* const PHAnimationCategoryPipes = @"Pipes";
NSString* const PHAnimationCategoryPixelHeart = @"Pixel Heart";
NSString* const PHAnimationCategoryShapes = @"Shapes";
NSString* const PHAnimationCategoryTrippy = @"Trippy";
NSString* const PHAnimationCategoryGames = @"Games";
NSString* const PHAnimationCategoryScripts = @"Scripts";
NSString* const PHAnimationCategoryLiB = @"LiB";

static NSString* const kDefiningPropertiesKey = @"kDefiningPropertiesKey";

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
  NSImage *previewImage = [self previewImage];
  if (nil != previewImage) {
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)[previewImage TIFFRepresentation], NULL);
    CGImageRef imageRef =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
    CGContextScaleCTM(cx, 1, -1);
    CGContextTranslateCTM(cx, 0, -size.height);
    CGContextDrawImage(cx, CGRectMake(0, 0, size.width, size.height), imageRef);
    CGImageRelease(imageRef);
    CFRelease(source);
  }
}

- (NSImage *)previewImage {
  return nil;
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
    [PHMotionBlurAnimation animation],
    [PHMaskAnimation animation],
    [PHTrippyTunnelAnimation animation],

    // Filters (commented out ones don't work)
    [PHAffineTileFilter animation],
    [PHBloomFilter animation],
    [PHBoxBlurFilter animation],
    [PHCheckerboardGeneratorFilter animation],
    [PHCircleSplashDistortionFilter animation],
    [PHColorInvertFilter animation],
    //[PHComicFilter animation],
    [PHDiscBlurFilter animation],
    [PHDotScreenFilter animation],
    [PHDrosteFilter animation],
    [PHEdgesFilter animation],
//    [PHEdgeWorkFilter animation],
    [PHEightfoldReflectedTileFilter animation],
    [PHExposureAdjustFilter animation],
    [PHFalseColorFilter animation],
//    [PHBumpDistortionFilter animation],
//    [PHHoleDistortionFilter animation],
    [PHKaleidoscopeFilter animation],
    [PHTriangleTileFilter animation],
    [PHColorSpliceAnimation animation],
    
    // Animations
    [PHPixelHeartAnimation animation],
    [PHPixelHeartTextAnimation animation],
    [PHRainbowHeartAnimation animation],
    [PHGifAnimation animation],
    [PHDancingGifsAnimation animation],
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
    [PHFlyingFireballAnimation animation],
    [PHRotatingSquaresAnimation animation],
    [PHLaunchpadDemoAnimation animation],
    [PHPixelLifeAnimation animation],
    [PHDancingManAnimation animation],
    [PHPixelTunnelAnimation animation],
    [PHSoundBoxAnimation animation],
    [PHFlowyColorsAnimation animation],
    [PHScreenCaptureAnimation animation],
    [PHKinectAnimation animation],
    [PHMandelbrotAnimation animation],
    [PHStaticAnimation animation],
    [PHClockAnimation animation],
    [PHDoLabAnimation animation],
    [PHTwistedAnimation animation],
    [PHSoundWaveAnimation animation],    
    [PHFlippingSquaresAnimation animation],
    [PHPositiveStatementsAnimation animation],
    [PHRaindropRipplesAnimation animation],

    // Sprites
    [PHMegamanAnimation animation],
    [PHPikachuEmotingAnimation animation],
    [PHAdventureTimeAnimation animation],
    [PHSophJoyAnimation animation],
    [PHNyanCatAnimation animation],
    [PHMarioAnimation animation],

    // Games
    [PHTronAnimation animation],
    ];

  // Obsolete animations.
  //[PHCornerParticlesAnimation animation],
  //[PHSpectrumLinesAnimation animation],
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

  if (nil != sAdditionalAnimationBlock) {
    animations = [animations arrayByAddingObjectsFromArray:sAdditionalAnimationBlock()];
  }

  return animations;
}

+ (NSArray *)allCategories {
  return @[
    PHAnimationCategoryPipes,
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

- (NSString *)guid {
  id definingProperties = [self definingProperties];
  if (definingProperties) {
    return [[self className] stringByAppendingFormat:@"%@", definingProperties];
  } else {
    return [self className];
  }
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
