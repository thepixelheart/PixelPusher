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
#import "PHBouncingCircleAnimation.h"
#import "PHBassPlate.h"
#import "PHFireworksAnimation.h"
#import "PHFlyingFireballAnimation.h"
#import "PHNoAnimation.h"
#import "PHMegamanAnimation.h"
#import "PHPikachuEmotingAnimation.h"
#import "PHSineWaveAnimation.h"
#import "PHPsychadelicBackgroundAnimation.h"

@implementation PHAnimation

+ (id)animation {
  return [[self alloc] init];
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  // No-op.
}

+ (NSArray *)allAnimations {
  return
  @[[PHNoAnimation animation],
  [PHBouncingCircleAnimation animation],
  [PHBassPlate animation],
  [PHFireworksAnimation animation],
  [PHFlyingFireballAnimation animation],
  [PHMegamanAnimation animation],
  [PHPikachuEmotingAnimation animation],
  [PHSineWaveAnimation animation],
  [PHPsychadelicBackgroundAnimation animation]];
}

@end
