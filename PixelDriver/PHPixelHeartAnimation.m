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
  PHSpritesheet* _spritesheet;

  PHSpriteAnimation* _animation;
}

- (id)init {
  if ((self = [super init])) {
    _spritesheet = [[PHSpritesheet alloc] initWithName:@"pixelheart" spriteSize:CGSizeMake(26, 23)];
    _animation = [[PHSpriteAnimation alloc] initWithSpritesheet:_spritesheet];
    [_animation addStillFrameAtX:0 y:0];
    _animation.repeats = YES;
    _animation.bounces = NO;
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  if (self.driver.unifiedSpectrum) {
    CGContextSaveGState(cx);
    CGSize spriteSize = _spritesheet.spriteSize;

    CGFloat maxRadius = MIN(spriteSize.width, spriteSize.height) / 2;

    CGFloat value = self.bassDegrader.value;
    if (value > 0.05) {
      CGImageRef imageRef = [_animation imageRefAtCurrentTick];
      CGRect heartFrame = CGRectMake(floorf((size.width - spriteSize.width) / 2),
                                     floorf((size.height - spriteSize.height) / 2),
                                     spriteSize.width,
                                     spriteSize.height);

      if (self.driver.motes.count > 0) {
        PHMote* mote = [self.driver.motes objectAtIndex:0];
        CGFloat degrees = mote.joystickDegrees;
        CGFloat radians = degrees * M_PI / 180;
        CGFloat tilt = mote.joystickTilt;

        heartFrame.origin.x = size.width / 2 - spriteSize.width / 2 + cosf(radians) * tilt * maxRadius;
        heartFrame.origin.y = size.height / 2 - spriteSize.height / 2 + sinf(radians) * tilt * maxRadius;
      }

      heartFrame = CGRectInset(heartFrame, (1 - value) * 10, (1 - value) * 10);
      CGContextSetAlpha(cx, MIN(1, value / 0.2));
      CGContextDrawImage(cx, heartFrame, imageRef);
      CGImageRelease(imageRef);
    }

    CGContextRestoreGState(cx);
  }
}

- (NSString *)tooltipName {
  return @"Pixel Heart";
}

@end
