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

#import "PHTwistedAnimation.h"

@implementation PHTwistedAnimation {
  CGFloat _advance;
  CGFloat _offsetAdvance;
  CGFloat _rotationAdvance;

  CGFloat _advance2;
  CGFloat _offsetAdvance2;
  CGFloat _rotationAdvance2;

  CGFloat _advance3;
  CGFloat _offsetAdvance3;
  CGFloat _rotationAdvance3;
}

- (void)renderStrandInContext:(CGContextRef)cx
                         size:(CGSize)size
              radiusAmplifier:(CGFloat)radiusAmplifier
                      advance:(CGFloat)advance
              rotationAdvance:(CGFloat)rotationAdvance
                       offset:(CGPoint)offset {
  CGContextSaveGState(cx);

  CGContextTranslateCTM(cx, size.width / 2, size.height / 2);
  CGContextRotateCTM(cx, -M_PI / 2 + rotationAdvance);
  CGContextTranslateCTM(cx, -size.width / 2, -size.height / 2);

  CGContextTranslateCTM(cx, offset.x, offset.y);

  CGFloat radius = 2 + (radiusAmplifier * 4);
  static const CGFloat kPeriodLength = 80;

  for (CGFloat line = 0; line < 6; ++line) {
    BOOL isDrawing = NO;
    for (CGFloat ix = -size.width / 2; ix < size.width * 2; ++ix) {
      CGFloat perc = (ix + advance + line * kPeriodLength / 3) / kPeriodLength;
      CGFloat percBounded = fast_fmod(perc, 1);
      CGFloat degree = percBounded * M_PI * 2 + M_PI * 120 / 180;

      CGFloat y = cos(degree) * radius + size.height / 2;
      BOOL shouldDraw = fast_fmod(perc, 2) < 0.84 ? YES : NO;
      if (shouldDraw != isDrawing) {
        if (!isDrawing) {
          CGContextMoveToPoint(cx, ix, y);
        } else {
          CGContextDrawPath(cx, kCGPathEOFillStroke);
        }
        isDrawing = shouldDraw;
      } else if (isDrawing) {
        CGContextAddLineToPoint(cx, ix, y);
      }
    }
    if (isDrawing) {
      CGContextDrawPath(cx, kCGPathEOFillStroke);
    }
  }

  CGContextRestoreGState(cx);
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);

  CGFloat alpha = 1;

  _advance3 += self.secondsSinceLastTick * 180 / M_PI * 1.1;
  _offsetAdvance3 -= self.secondsSinceLastTick * 0.05;
  _rotationAdvance3 -= self.secondsSinceLastTick * 0.01 * (self.vocalDegrader.value + 1) * cos(_offsetAdvance3 / 180);
  alpha = sqrt(self.vocalDegrader.value);
  CGContextSetFillColorWithColor(cx, [NSColor colorWithDeviceRed:0 green:1 blue:0 alpha:alpha].CGColor);
  CGContextSetStrokeColorWithColor(cx, [NSColor colorWithDeviceRed:0.5 green:1 blue:0.5 alpha:alpha].CGColor);
  [self renderStrandInContext:cx
                         size:size
              radiusAmplifier:self.vocalDegrader.value
                      advance:_advance3
              rotationAdvance:_rotationAdvance3
                       offset:CGPointMake(sin(_offsetAdvance2 * 13) * 10, cos(_offsetAdvance3 * 7) * 10)];

  _advance2 += self.secondsSinceLastTick * 180 / M_PI * 0.9;
  _offsetAdvance2 -= self.secondsSinceLastTick * 0.02;
  _rotationAdvance2 -= self.secondsSinceLastTick * 0.05 * (self.hihatDegrader.value + 1) * cos(_offsetAdvance2 / 180);
  alpha = sqrt(self.hihatDegrader.value);
  CGContextSetFillColorWithColor(cx, [NSColor colorWithDeviceRed:0 green:0 blue:1 alpha:alpha].CGColor);
  CGContextSetStrokeColorWithColor(cx, [NSColor colorWithDeviceRed:0.5 green:0.5 blue:1 alpha:alpha].CGColor);
  [self renderStrandInContext:cx
                         size:size
              radiusAmplifier:self.hihatDegrader.value
                      advance:_advance2
              rotationAdvance:_rotationAdvance2
                       offset:CGPointMake(cos(_offsetAdvance2 * 19) * 10, sin(_offsetAdvance2 * 13) * 10)];

  _advance += self.secondsSinceLastTick * 180 / M_PI;
  _offsetAdvance += self.secondsSinceLastTick * 0.07;
  _rotationAdvance += self.secondsSinceLastTick * 0.1 * (self.bassDegrader.value + 1) * cos(_offsetAdvance / 180);
  alpha = sqrt(self.bassDegrader.value);
  CGContextSetFillColorWithColor(cx, [NSColor colorWithDeviceRed:1 green:0 blue:0 alpha:alpha].CGColor);
  CGContextSetStrokeColorWithColor(cx, [NSColor colorWithDeviceRed:1 green:0.5 blue:0.5 alpha:alpha].CGColor);
  [self renderStrandInContext:cx
                         size:size
              radiusAmplifier:self.bassDegrader.value
                      advance:_advance
              rotationAdvance:_rotationAdvance
                       offset:CGPointMake(cos(_offsetAdvance * 3) * 10, sin(_offsetAdvance * 7) * 10)];

  CGContextRestoreGState(cx);
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  [self.bassDegrader tickWithPeak:1];
  [self.vocalDegrader tickWithPeak:1];
  [self.hihatDegrader tickWithPeak:1];
  [self renderBitmapInContext:cx size:size];
}

- (NSString *)tooltipName {
  return @"Twisted";
}

- (NSArray *)categories {
  return @[
           PHAnimationCategoryTrippy
           ];
}

@end
