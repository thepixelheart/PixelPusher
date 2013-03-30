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

#import "PHSpiralingSquareAnimation.h"

@implementation PHSpiralingSquareAnimation {
  CGPoint _spiralCenterPoint;
  CGFloat _accum;
}

- (id)init {
  if ((self = [super init])) {
    _spiralCenterPoint = CGPointMake(kWallWidth / 2, kWallHeight / 2);
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);

  CGRect currentPixelFrame = CGRectMake(_spiralCenterPoint.x, _spiralCenterPoint.y, 1, 1);
  CGPoint direction = CGPointMake(1, 0);
  _accum += self.secondsSinceLastTick * 0.5 * (self.bassDegrader.value + 1);
  CGFloat colorOffset = _accum;
  BOOL isFirstStep = YES;
  NSInteger stepLength = 1;
  NSInteger stepWalk = 0;
  CGFloat increase = 0.001 * self.snareDegrader.value;
  while (stepLength < kWallWidth + 12) {
    NSColor *color = [NSColor colorWithDeviceHue:1 - fmodf(colorOffset, 1)
                                      saturation:self.hihatDegrader.value * 0.5 + 0.5
                                      brightness:1
                                           alpha:1];
    CGContextSetFillColorWithColor(cx, color.CGColor);
    CGContextFillRect(cx, currentPixelFrame);

    currentPixelFrame.origin.x += direction.x;
    currentPixelFrame.origin.y += direction.y;

    stepWalk++;

    if (stepWalk == stepLength) {
      if (!isFirstStep) {
        stepLength++;
      }

      stepWalk = 0;

      CGFloat temp = direction.x;
      if (isFirstStep) {
        direction.x = direction.y;
      } else {
        direction.x = -direction.y;
      }
      direction.y = temp;

      isFirstStep = !isFirstStep;
    }

    colorOffset += increase;
  }

  CGContextRestoreGState(cx);
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  [self renderBitmapInContext:cx size:size];
}

- (NSString *)tooltipName {
  return @"Spiraling Square";
}

- (NSArray *)categories {
  return @[
           PHAnimationCategoryShapes
           ];
}

@end
