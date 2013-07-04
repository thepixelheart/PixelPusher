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

#import "PHPixelHeartTextAnimation.h"

@implementation PHPixelHeartTextAnimation {
  PHSpritesheet* _pixelHeartTextSpritesheet;
}

- (id)init {
  if ((self = [super init])) {
    _pixelHeartTextSpritesheet = [[PHSpritesheet alloc] initWithName:@"pixelhearttext"
                                                          spriteSize:CGSizeMake(42, 7)];
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGImageRef imageRef = [_pixelHeartTextSpritesheet imageAtX:0 y:0];
  CGSize textSize = _pixelHeartTextSpritesheet.spriteSize;
  CGContextSetAlpha(cx, 1);
  CGContextDrawImage(cx, CGRectMake(floorf((kWallWidth - textSize.width) / 2),
                                    floorf((kWallHeight - textSize.height) / 2),
                                    textSize.width, textSize.height), imageRef);
  CGImageRelease(imageRef);
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  [self renderBitmapInContext:cx size:size];
}

- (NSString *)tooltipName {
  return @"Pixel Heart Text";
}

- (NSArray *)categories {
  return @[
           PHAnimationCategoryPixelHeart
           ];
}

@end
