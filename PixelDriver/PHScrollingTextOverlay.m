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

#import "PHScrollingTextOverlay.h"
#import "AppDelegate.h"

static const CGFloat kTextHeight = 5;
static const CGFloat kFontSize = 10;
static const CGFloat kScrollSpeed = 8;

@implementation PHScrollingTextOverlay {
  NSString *_text;
  NSFont* _font;
  CGFloat _textAdvance;
}

- (id)init {
  if ((self = [super init])) {
    _font = [NSFont fontWithName:@"Visitor TT1 BRK" size:kFontSize];
  }
  return self;
}

+ (id)overlayWithText:(NSString *)text {
  PHScrollingTextOverlay *overlay = [self overlay];
  overlay->_text = text;
  return overlay;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);

  CGSize textSize = NSSizeToCGSize([_text sizeWithAttributes:
                                    @{NSFontAttributeName:_font}]);

  _textAdvance += self.secondsSinceLastTick * kScrollSpeed;
  CGFloat offsetX = -floorf(_textAdvance) + size.width;
  {
    CGContextSaveGState(cx);
    CGContextSetFillColorWithColor(cx, [[NSColor whiteColor] CGColor]);
    CGContextFillRect(cx, CGRectMake(offsetX, 0, textSize.width + 1, kTextHeight));
    CGContextRestoreGState(cx);
  }

  {
    CGContextSaveGState(cx);
    CGContextSetRGBFillColor(cx, 0, 0, 0, 1);
    CGContextSetTextMatrix(cx,
                           CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, 0.0));
    CGContextSelectFont(cx,
                        [_font.fontName cStringUsingEncoding:NSUTF8StringEncoding],
                        _font.pointSize,
                        kCGEncodingMacRoman);
    CGContextShowTextAtPoint(cx,
                             offsetX + 1,
                             kTextHeight,
                             [_text cStringUsingEncoding:NSUTF8StringEncoding],
                             _text.length);
    CGContextRestoreGState(cx);
  }

  CGContextRestoreGState(cx);
  
  if (_textAdvance > textSize.width + size.width) {
    // TODO: Add support for overlays again.
    //[PHApp() removeOverlay:self];
  }
}

@end
