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

#import "PHCountdownAnimation.h"

static const CGFloat kFontSize = 40;
static const CGFloat kYearFontSize = 20;
static const CGFloat kCrushPercStart = 0.5;
static const CGFloat kFallPercStart = 0.4;

@implementation PHCountdownAnimation {
  NSFont* _font;
  NSFont* _yearFont;
  NSTimeInterval _timestampToCountdownTo;
}

- (id)init {
  if ((self = [super init])) {
    NSDateComponents* dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = 2013;
    [dateComponents setCalendar:[NSCalendar currentCalendar]];
    _timestampToCountdownTo = [[dateComponents date] timeIntervalSinceReferenceDate];
    _timestampToCountdownTo = [NSDate timeIntervalSinceReferenceDate] + 11;

    _font = [NSFont fontWithName:@"Visitor TT1 BRK" size:kFontSize];
    _yearFont = [NSFont fontWithName:@"Visitor TT1 BRK" size:kYearFontSize];
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);
  NSTimeInterval timeLeft = _timestampToCountdownTo - [NSDate timeIntervalSinceReferenceDate];

  CGContextScaleCTM(cx, 1, -1);
  CGContextTranslateCTM(cx, 0, -size.height);

  // Count down!
  if (timeLeft > 0 && timeLeft <= 10) {
    CGContextSetFillColorWithColor(cx, [[NSColor blackColor] CGColor]);

    CGContextFillRect(cx, CGRectMake(0, 0, size.width, size.height));

    CGContextSetFillColorWithColor(cx, [[NSColor whiteColor] CGColor]);

    NSInteger secondsRemaining = ceilf(timeLeft);
    CGFloat percentageComplete = ((NSTimeInterval)secondsRemaining - timeLeft);

    CGContextSelectFont(cx,
                        [_font.fontName cStringUsingEncoding:NSUTF8StringEncoding],
                        _font.pointSize,
                        kCGEncodingMacRoman);

    NSString* secondsRemainingAsString = [NSString stringWithFormat:@"%ld", secondsRemaining];
    NSString* nextSecondRemainingAsString = [NSString stringWithFormat:@"%ld", secondsRemaining - 1];
    CGContextSetRGBFillColor(cx, 1, 1, 1, 1);
    CGContextTranslateCTM(cx, 2, 6);

    CGContextSaveGState(cx);
    if (secondsRemaining >= 2) {
      if (percentageComplete >= kCrushPercStart) {
        CGFloat tween = PHEaseIn((percentageComplete - kCrushPercStart)
                                 / (1 - kCrushPercStart));
        CGContextScaleCTM(cx, 1, 1 - tween);
      }
    } else if (secondsRemaining == 1) {
      CGFloat tween = PHEaseIn(percentageComplete);
      CGContextSetAlpha(cx, 1 - tween);
    }
    CGSize textSize = NSSizeToCGSize([secondsRemainingAsString sizeWithAttributes:
                                      @{NSFontAttributeName:_font}]);
    CGContextShowTextAtPoint(cx,
                             floorf((size.width - textSize.width) / 2.),
                             0,
                             [secondsRemainingAsString cStringUsingEncoding:NSUTF8StringEncoding],
                             secondsRemainingAsString.length);
    CGContextRestoreGState(cx);

    CGContextSaveGState(cx);

    CGSize nextTextSize = NSSizeToCGSize([nextSecondRemainingAsString sizeWithAttributes:
                                          @{NSFontAttributeName:_font}]);

    BOOL shouldDrawNextSecond = NO;
    if (secondsRemaining >= 2) {
      if (percentageComplete >= kCrushPercStart) {
        shouldDrawNextSecond = YES;
        CGFloat tween = PHEaseIn((percentageComplete - kCrushPercStart)
                                 / (1 - kCrushPercStart));
        CGContextTranslateCTM(cx, 0, (1 - tween) * (kWallHeight - 12));

      } else if (percentageComplete >= kFallPercStart) {
        shouldDrawNextSecond = YES;
        CGFloat tween = PHEaseIn((percentageComplete - kFallPercStart)
                                 / (kCrushPercStart - kFallPercStart));
        CGContextTranslateCTM(cx, 0, kWallHeight - 12 + (1 - tween) * 6);
      }
    }

    if (shouldDrawNextSecond) {
      CGContextShowTextAtPoint(cx,
                               floorf((size.width - nextTextSize.width) / 2.),
                               0,
                               [nextSecondRemainingAsString cStringUsingEncoding:NSUTF8StringEncoding],
                               nextSecondRemainingAsString.length);
    }
    CGContextRestoreGState(cx);

  } else if (timeLeft <= 0) {
    CGContextSetFillColorWithColor(cx, [[NSColor whiteColor] CGColor]);

    CGContextSelectFont(cx,
                        [_yearFont.fontName cStringUsingEncoding:NSUTF8StringEncoding],
                        _yearFont.pointSize,
                        kCGEncodingMacRoman);
    CGContextTranslateCTM(cx, 1, 11);

    NSString* year = @"2013";

    CGSize yearSize = NSSizeToCGSize([year sizeWithAttributes:@{NSFontAttributeName:_yearFont}]);
    CGContextShowTextAtPoint(cx,
                             floorf((size.width - yearSize.width) / 2.),
                             0,
                             [year cStringUsingEncoding:NSUTF8StringEncoding],
                             year.length);
  }
  CGContextRestoreGState(cx);
}

- (NSString *)tooltipName {
  return @"Countdown";
}

@end
