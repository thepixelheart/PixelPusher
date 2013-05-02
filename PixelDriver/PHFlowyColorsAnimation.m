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

#import "PHFlowyColorsAnimation.h"

@implementation PHFlowyColorsAnimation {
  CGFloat _advance;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);

  for (NSInteger ix = 0; ix < size.width * size.height; ++ix) {
    CGFloat x = ix / (NSInteger)size.height;
    CGFloat y = ix % (NSInteger)size.height;
    CGRect pixel = CGRectMake(x, y, 1, 1);

    CGFloat offset = (CGFloat)ix * (0.005 * (((self.animationTick.hardwareState.fader + 0.5) * 0.7) + 0.3) * 10) + _advance;
    CGFloat red = sin(offset) * 0.3 + 0.7;
    CGFloat green = cos(offset * 0.5 + M_PI_2) * 0.3 + 0.7;
    CGFloat blue = sin(offset * 0.7 - M_PI_4) * 0.3 + 0.7;
    CGContextSetFillColorWithColor(cx, [NSColor colorWithDeviceRed:red green:green blue:blue alpha:1].CGColor);
    CGContextFillRect(cx, pixel);
  }

  _advance += self.secondsSinceLastTick * 10 * (self.bassDegrader.value * 3 + 1);

  CGContextRestoreGState(cx);
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  [self renderBitmapInContext:cx size:size];
}

- (NSString *)tooltipName {
  return @"Flowy Colors";
}

- (NSArray *)categories {
  return @[PHAnimationCategoryTrippy];
}

@end
