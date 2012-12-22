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

#import "PHMegamanAnimation.h"

@implementation PHMegamanAnimation {
  PHSpritesheet* _spritesheet;
  PHSpriteAnimation* _runningAnimation;
}

- (id)init {
  if ((self = [super init])) {
    _spritesheet = [[PHSpritesheet alloc] initWithName:@"megaman-nes-blue" spriteSize:CGSizeMake(32, 32)];

    _runningAnimation = [[PHSpriteAnimation alloc] initWithSpritesheet:_spritesheet];
    _runningAnimation.bounces = YES;
    _runningAnimation.repeats = YES;
    [_runningAnimation addFrameAtX:2 y:0 duration:0.12];
    [_runningAnimation addFrameAtX:3 y:0 duration:0.12];
    [_runningAnimation addFrameAtX:4 y:0 duration:0.12];
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  if (self.driver.spectrum) {
    CGImageRef imageRef = [_runningAnimation imageRefAtCurrentTick];

    CGContextDrawImage(cx, CGRectMake(0, 0, _spritesheet.spriteSize.width, _spritesheet.spriteSize.height), imageRef);

    CGImageRelease(imageRef);
  }
}

@end
