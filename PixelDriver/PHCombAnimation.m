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

#import "PHCombAnimation.h"

@implementation PHCombAnimation {
  CGFloat _colorAdvance;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);

  CGFloat scale = 1 + self.vocalDegrader.value * 4;

  _colorAdvance += self.secondsSinceLastTick / 8;

  CGFloat amplitude = self.bassDegrader.value;
  if (amplitude < 0.1) {
    CGContextSetAlpha(cx, 1 - amplitude / 0.1);
  }
  // Draw left side.
  BOOL flipper = NO;

  BOOL colorize = YES;
  if (self.driver.isUserButton1Pressed
      || self.driver.isUserButton2Pressed) {
    colorize = NO;
    CGContextSetFillColorWithColor(cx, [NSColor whiteColor].CGColor);
  }

  CGFloat height = amplitude * size.height;
  CGRect fillTopRect = CGRectMake(0, 0, scale, height);
  CGRect fillBottomRect = CGRectMake(0, size.height - height, scale, height);
  CGFloat degradingScale = scale;
  for (CGFloat ix = size.width / 2 - scale; ix >= -scale; ix -= degradingScale) {
    if (colorize) {
      NSColor* color = [NSColor colorWithDeviceHue:1 - fmodf(_colorAdvance + ix / 180, 1)
                                        saturation:1
                                        brightness:(self.hihatDegrader.value * 0.5 + 0.5)
                                             alpha:1];
      CGContextSetFillColorWithColor(cx, color.CGColor);
    }

    CGRect frame = flipper ? fillTopRect : fillBottomRect;
    frame.origin.x = ix;
    CGContextFillRect(cx, frame);
    flipper = !flipper;
    degradingScale = MAX(1, degradingScale - 0.1);
  }

  degradingScale = scale;
  flipper = YES;
  for (CGFloat ix = size.width / 2; ix < size.width; ix += degradingScale) {
    if (colorize) {
      NSColor* color = [NSColor colorWithDeviceHue:1 - fmodf(_colorAdvance + ix / 180, 1)
                                        saturation:1
                                        brightness:(self.hihatDegrader.value * 0.5 + 0.5)
                                             alpha:1];
      CGContextSetFillColorWithColor(cx, color.CGColor);
    }

    CGRect frame = flipper ? fillTopRect : fillBottomRect;
    frame.origin.x = ix;
    CGContextFillRect(cx, frame);
    flipper = !flipper;
    degradingScale = MAX(1, degradingScale - 0.1);
  }

  CGContextRestoreGState(cx);
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  [self.bassDegrader tickWithPeak:0.4];
  [self.hihatDegrader tickWithPeak:1];
  [self renderBitmapInContext:cx size:size];
}

- (NSString *)tooltipName {
  return @"Comb";
}

- (NSArray *)categories {
  return @[
    PHAnimationCategoryShapes
  ];
}

@end
