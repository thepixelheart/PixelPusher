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

#import "PHDoLabAnimation.h"

@implementation PHDoLabAnimation {
  CGFloat _accum;
  CGFloat _accum2;
  CGFloat _accum3;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);

  _accum += self.secondsSinceLastTick * (self.bassDegrader.value * 3 + 1);
  _accum2 += self.secondsSinceLastTick * (self.hihatDegrader.value * 3 + 1);
  _accum3 += self.secondsSinceLastTick * (self.vocalDegrader.value * 3 + 1);

  CGContextSetFillColorWithColor(cx, [NSColor purpleColor].CGColor);

  CGFloat xCenter = 24;
  for (CGFloat iy = 0; iy < size.height - 8; iy += 2) {
    CGFloat perc = iy / size.height;
    CGFloat period = cos(perc * M_PI_2 * 1.3);
    CGFloat radius = powf(period, 2) * 3 * (self.vocalDegrader.value * 1.5 + 1);
    CGFloat offset = powf(sin(perc * M_PI - M_PI * 20 / 180 + _accum3), 2) * radius * 0.5 * sqrt(perc);

    CGContextFillRect(cx, CGRectMake(xCenter - radius + offset, size.height - iy, radius * 2, 1));
  }

  CGContextSetFillColorWithColor(cx, [NSColor redColor].CGColor);

  xCenter = 12;
  for (CGFloat iy = 0; iy < size.height - 2; iy += 2) {
    CGFloat perc = iy / size.height;
    CGFloat period = cos(perc * M_PI_2 - M_PI * 20 / 180);
    CGFloat radius = powf(period, 4) * 5 * (self.bassDegrader.value + 1);
    CGFloat offset = powf(sin(perc * M_PI - M_PI * 20 / 180 + _accum), 2) * radius * 0.5 * sqrt(perc);

    CGContextFillRect(cx, CGRectMake(xCenter - radius + offset, size.height - iy + 1, radius * 2, 1));
  }

  CGContextSetFillColorWithColor(cx, [NSColor blueColor].CGColor);

  xCenter = 36;
  for (CGFloat iy = 0; iy < size.height - 2; iy += 2) {
    CGFloat perc = iy / size.height;
    CGFloat period = cos(perc * M_PI_2);
    CGFloat radius = powf(period, 2) * 3 * (self.hihatDegrader.value * 1.5 + 1);
    CGFloat offset = powf(sin(perc * M_PI - M_PI * 20 / 180 + _accum2), 2) * radius * 0.5 * sqrt(perc);

    CGContextFillRect(cx, CGRectMake(xCenter - radius + offset, size.height - iy + 1, radius * 2, 1));
  }

  CGContextRestoreGState(cx);
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  [self renderBitmapInContext:cx size:size];
}

- (NSString *)tooltipName {
  return @"Do Lab";
}

- (NSArray *)categories {
  return @[
           PHAnimationCategoryShapes,
           PHAnimationCategoryLiB
           ];
}

@end
