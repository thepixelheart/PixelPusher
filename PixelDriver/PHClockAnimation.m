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

#import "PHClockAnimation.h"

static const CGFloat kFontSize = 20;

@implementation PHClockAnimation {
  NSFont* _font;
  NSDateFormatter* _formatter;
}

- (id)init {
  if ((self = [super init])) {
    _font = [NSFont fontWithName:@"Visitor TT1 BRK" size:kFontSize];

    _formatter = [[NSDateFormatter alloc] init];
    [_formatter setDateFormat:@"h:mm"];
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);

  CGContextScaleCTM(cx, 1, -1);
  CGContextTranslateCTM(cx, 0, -size.height);

  CGContextSelectFont(cx,
                      [_font.fontName cStringUsingEncoding:NSUTF8StringEncoding],
                      _font.pointSize,
                      kCGEncodingMacRoman);

  NSString* string = [_formatter stringFromDate:[NSDate date]];
  {
    CGContextSaveGState(cx);
    CGContextSetRGBFillColor(cx, 1, 1, 1, 1);
    CGSize textSize = NSSizeToCGSize([string sizeWithAttributes:
                                      @{NSFontAttributeName:_font}]);
    CGContextTranslateCTM(cx, 2, 11);
    CGContextShowTextAtPoint(cx,
                             floorf((size.width - textSize.width) / 2.),
                             0,
                             [string cStringUsingEncoding:NSUTF8StringEncoding],
                             string.length);
    CGContextRestoreGState(cx);
  }

  CGContextRestoreGState(cx);
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  [self renderBitmapInContext:cx size:size];
}

- (NSString *)tooltipName {
  return @"Clock";
}

- (NSArray *)categories {
  return @[PHAnimationCategoryLiB];
}

@end
