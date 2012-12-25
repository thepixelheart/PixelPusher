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

#import "PHPixelHeartAnimation.h"

@implementation PHPixelHeartAnimation {
  PHDegrader* _bassDegrader;
  PHSpritesheet* _spritesheet;

  PHSpriteAnimation* _animation;
}

- (id)init {
  if ((self = [super init])) {
    _bassDegrader = [[PHDegrader alloc] init];

    _spritesheet = [[PHSpritesheet alloc] initWithName:@"pixelheart" spriteSize:CGSizeMake(26, 23)];
    _animation = [[PHSpriteAnimation alloc] initWithSpritesheet:_spritesheet];
    [_animation addStillFrameAtX:0 y:0];
    _animation.repeats = YES;
    _animation.bounces = NO;
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  if (self.driver.spectrum) {
    [_bassDegrader tickWithPeak:self.driver.subBassAmplitude];
    CGSize spriteSize = _spritesheet.spriteSize;

    CGFloat value = (_bassDegrader.value - 0.2) / 0.8;
    if (value > 0.2) {
      CGImageRef imageRef = [_animation imageRefAtCurrentTick];
      CGRect heartFrame = CGRectMake(floorf((size.width - spriteSize.width) / 2),
                                     floorf((size.height - spriteSize.height) / 2),
                                     spriteSize.width,
                                     spriteSize.height);
      heartFrame = CGRectInset(heartFrame, (1 - value) * 10, (1 - value) * 10);
      CGContextDrawImage(cx, heartFrame, imageRef);

      CGImageRelease(imageRef);
    }
  }
}

@end
