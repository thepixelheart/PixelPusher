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

#import "PHMtFujiAnimation.h"

@implementation PHMtFujiAnimation

- (void)drawSkyInContext:(CGContextRef)cx size:(CGSize)size {
  CGRect rect = CGRectMake(0, 0, size.width, size.height);
  CGContextSetRGBFillColor(cx, 128.f / 255.f, 213.f / 255.f, 255.f / 255.f, 1);
  CGContextFillRect(cx, rect);
}

- (void)drawWaterInContext:(CGContextRef)cx size:(CGSize)size {
  CGRect rect = CGRectMake(0, size.height / 2, size.width, size.height / 2);
  CGContextSetRGBFillColor(cx, 0.f / 255.f, 170.f / 255.f, 255.f / 255.f, 1);
  CGContextFillRect(cx, rect);
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  [self drawSkyInContext:cx size:size];
  [self drawWaterInContext:cx size:size];
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  [self renderBitmapInContext:cx size:size];
}

- (NSString *)tooltipName {
  return @"Mt Fuji";
}

- (NSArray *)categories {
  return @[
           PHAnimationCategorySprites
           ];
}

@end
