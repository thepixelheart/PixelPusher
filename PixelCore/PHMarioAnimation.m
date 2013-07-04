//
// Copyright 2012-2013 Jeff Verkoeyen
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

#import "PHMarioAnimation.h"

@implementation PHMarioAnimation {
  PHSpritesheet* _marioSpritesheet;
  PHSpriteAnimation* _runningAnimation;
}

- (id)init {
  if ((self = [super init])) {
    _marioSpritesheet = [[PHSpritesheet alloc] initWithName:@"mario" spriteSize:CGSizeMake(16, 32)];

    _runningAnimation = [[PHSpriteAnimation alloc] initWithSpritesheet:_marioSpritesheet];
    _runningAnimation.repeats = YES;
    [_runningAnimation addFrameAtX:0 y:0 duration:0.12];
    [_runningAnimation addFrameAtX:1 y:0 duration:0.12];
    [_runningAnimation addFrameAtX:2 y:0 duration:0.12];
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGImageRef imageRef = nil;

  imageRef = [_runningAnimation imageRefWithDelta:self.secondsSinceLastTick];
  CGSize marioSize = _marioSpritesheet.spriteSize;
  CGContextDrawImage(cx, CGRectMake(floor((size.width - marioSize.width) / 2), 0, marioSize.width, marioSize.height), imageRef);
  CGImageRelease(imageRef);
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  [self renderBitmapInContext:cx size:size];
}

- (NSString *)tooltipName {
  return @"Mario";
}

- (NSArray *)categories {
  return @[
           PHAnimationCategorySprites
           ];
}

@end
