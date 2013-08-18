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

#import "PHRainbowHeartAnimation.h"

@implementation PHRainbowHeartAnimation {
  CGFloat _scaleAdvance;
  CGFloat _colorAdvance;
  NSMutableArray* _colors;
}

- (id)init {
  if ((self = [super init])) {
    _colors = [NSMutableArray array];
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);

  CGContextSetInterpolationQuality(cx, kCGInterpolationNone);

  _scaleAdvance += self.secondsSinceLastTick * (2 * (self.bassDegrader.value + 0.2));

  CGRect frame = CGRectMake(0, 0, size.width, size.height);
  CGContextScaleCTM(cx, 1, -1);
  CGContextTranslateCTM(cx, 0, -size.height);

  CGFloat scaleDelta = 0.25;
  CGFloat scaleOffset = fmod(_scaleAdvance, scaleDelta);
  CGFloat scale = 4 + scaleOffset;

  _colorAdvance += self.secondsSinceLastTick * 0.2;

  [_colors removeAllObjects];
  for (NSInteger ix = 0; ix < 40; ++ix) {
    CGFloat offset = _colorAdvance + (CGFloat)ix * 0.05;
    CGFloat red = sin(offset) * 0.5 + 0.5;
    CGFloat green = cos(offset * 5 + M_PI_2) * 0.5 + 0.5;
    CGFloat blue = sin(offset * 13 - M_PI_4) * 0.5 + 0.5;
    [_colors addObject:[NSColor colorWithDeviceRed:red green:green blue:blue alpha:1]];
  }

  NSInteger colorOffset = (NSInteger)floor(_scaleAdvance / scaleDelta) % _colors.count;
  if (colorOffset < 0) {
    colorOffset = _colors.count + colorOffset;
  }

  for (NSInteger ix = 0; ix < _colors.count; ++ix) {
    NSColor* color = _colors[(ix + colorOffset) % _colors.count];
    CGContextSaveGState(cx);
    CGContextTranslateCTM(cx, size.width / 2, size.height / 2);
    CGContextScaleCTM(cx, scale, scale);
    CGContextTranslateCTM(cx, -size.width / 2, -size.height / 2);

    CGContextBeginPath(cx);

    CGPoint midPoint = CGPointMake(size.width / 2, size.height / 2);
    CGContextMoveToPoint(cx, midPoint.x, midPoint.y + size.height / 8);
    CGFloat widthFactor = 4;
    CGContextAddCurveToPoint(cx,
                             midPoint.x, midPoint.y + size.height / 2.5,
                             midPoint.x - size.width / widthFactor, midPoint.y + size.height / 2.5,
                             midPoint.x - size.width / widthFactor, midPoint.y + size.height / 8);
    CGContextAddCurveToPoint(cx,
                             midPoint.x - size.width / widthFactor, midPoint.y - size.height / 6,
                             midPoint.x, midPoint.y - size.height / 6,
                             midPoint.x, midPoint.y - size.height / 2.5);
    CGContextAddCurveToPoint(cx,
                             midPoint.x, midPoint.y - size.height / 6,
                             midPoint.x + size.width / widthFactor, midPoint.y - size.height / 6,
                             midPoint.x + size.width / widthFactor, midPoint.y + size.height / 8);
    CGContextAddCurveToPoint(cx,
                             midPoint.x + size.width / widthFactor, midPoint.y + size.height / 2.5,
                             midPoint.x, midPoint.y + size.height / 2.5,
                             midPoint.x, midPoint.y + size.height / 8);
    CGContextClosePath(cx);
    CGContextClip(cx);

    CGContextSetFillColorWithColor(cx, color.CGColor);
    CGContextFillRect(cx, frame);

    CGContextRestoreGState(cx);

    scale -= scaleDelta;
    if (scale <= 0) {
      break;
    }
  }

  CGContextRestoreGState(cx);
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  [self renderBitmapInContext:cx size:size];
}

- (NSArray *)categories {
  return @[PHAnimationCategoryPixelHeart];
}

- (NSString *)tooltipName {
  return @"Rainbow Heart";
}

@end
