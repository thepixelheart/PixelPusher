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
#import "PHNyanCatBgAnimation.h"
#import "PHNyanCatFgAnimation.h"
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
  return
  @[[PHResetAnimation animation],
  [PHSpectrumViewerAnimation animation],
  [PHRotationAnimation animationWithDirection:1],
  [PHRotationAnimation animationWithDirection:-1],
  [PHBassPlate animation],
  [PHFireworksAnimation animation],
  [PHFlyingFireballAnimation animation],
  [PHMegamanAnimation animation],
  [PHPikachuEmotingAnimation animation],
  [PHSineWaveAnimation animation],
  [PHPsychadelicBackgroundAnimation animation],
  [PHLevelsHorizAnimation animation],
  [PHNyanCatBgAnimation animation],
  [PHNyanCatFgAnimation animation],
  [PHPixelHeartAnimation animation],
  [PHFlyingRectAnimation animation],
  [PHGameOfLifeAnimation animation],
  [PHSimpleMoteAnimation animation],
  [PHTunnelGameAnimation animation],
  [PHCountdownAnimation animation],
  [PHRipplesAnimation animation],
  [PHRipplesAnimation animationStationary]];
}

- (NSString *)tooltipName {
  return NSStringFromClass([self class]);
}

@end
