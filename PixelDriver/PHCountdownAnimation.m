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
  CGFloat _colorAdvance;
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
    NSInteger secondsRemaining = ceilf(timeLeft);
    CGFloat percentageComplete = ((NSTimeInterval)secondsRemaining - timeLeft);

    if (secondsRemaining == 1) {
      CGContextSetAlpha(cx, 1 - percentageComplete);
    }

    _colorAdvance += self.secondsSinceLastTick / 8;

    CGContextSetFillColorWithColor(cx, [[NSColor grayColor] CGColor]);
    CGContextFillRect(cx, CGRectMake(0, 0, size.width, size.height));

    CGContextSelectFont(cx,
                        [_font.fontName cStringUsingEncoding:NSUTF8StringEncoding],
                        _font.pointSize,
                        kCGEncodingMacRoman);

    NSString* secondsRemainingAsString = [NSString stringWithFormat:@"%ld", secondsRemaining];

    {
      CGContextSaveGState(cx);
      CGContextSetRGBStrokeColor(cx, 0, 0, 0, 1);
      CGContextSetLineWidth(cx, 2);

      CGPoint centerPoint = CGPointMake(kWallWidth / 2, kWallHeight / 2);
      CGFloat radius = MAX(kWallWidth, kWallHeight);

      CGMutablePathRef path = CGPathCreateMutable();
      CGPathMoveToPoint(path, nil, centerPoint.x, centerPoint.y);
      CGPathAddLineToPoint(path, nil,
                           centerPoint.x + radius * cosf(percentageComplete * M_PI * 2 + M_PI_2),
                           centerPoint.x + radius * sinf(percentageComplete * M_PI * 2 + M_PI_2));
      CGContextAddPath(cx, path);

      CGContextStrokePath(cx);
      CGPathRelease(path);

      CGContextSetRGBFillColor(cx, 0, 0, 0, 1);
      CGContextFillRect(cx, CGRectMake(0, centerPoint.y - 0.5, size.width, 1));
      CGContextFillRect(cx, CGRectMake(centerPoint.x - 0.5, 0, 1, size.height));

      CGContextRestoreGState(cx);
    }

    {
      CGContextSaveGState(cx);
      CGContextSetRGBFillColor(cx, 0, 0, 0, 1);
      CGSize textSize = NSSizeToCGSize([secondsRemainingAsString sizeWithAttributes:
                                        @{NSFontAttributeName:_font}]);
      CGContextTranslateCTM(cx, 2, 6);
      CGContextShowTextAtPoint(cx,
                               floorf((size.width - textSize.width) / 2.),
                               0,
                               [secondsRemainingAsString cStringUsingEncoding:NSUTF8StringEncoding],
                               secondsRemainingAsString.length);
      CGContextRestoreGState(cx);
    }

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
