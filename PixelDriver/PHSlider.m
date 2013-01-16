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

#import "PHSlider.h"

@interface PHSliderCell : NSSliderCell
@end

@implementation PHSliderCell {
  NSImage* _sliderImageLeft;
  NSImage* _sliderImageMid;
  NSImage* _sliderImageMidHighlight;
  NSImage* _sliderImageRight;
  NSImage* _sliderBgImageLeft;
  NSImage* _sliderBgImageMid;
  NSImage* _sliderBgImageRight;
}

- (id)init {
  if ((self = [super init])) {
    _sliderImageLeft = [NSImage imageNamed:@"sliderLxx"];
    _sliderImageMid = [NSImage imageNamed:@"sliderxMx"];
    _sliderImageMidHighlight = [NSImage imageNamed:@"sliderxMxHighlight"];
    _sliderImageRight = [NSImage imageNamed:@"sliderxxR"];
    _sliderBgImageLeft = [NSImage imageNamed:@"sliderbgLxx"];
    _sliderBgImageMid = [NSImage imageNamed:@"sliderbgxMx"];
    _sliderBgImageRight = [NSImage imageNamed:@"sliderbgxxR"];
  }
  return self;
}

- (void)drawKnob:(NSRect)knobRect {
  NSDrawThreePartImage(knobRect, _sliderImageLeft, _sliderImageMid, _sliderImageRight, NO, kCGBlendModeSourceAtop, 1, NO);
  CGRect highlightRect = knobRect;
  highlightRect.size.width = _sliderImageMidHighlight.size.width;
  highlightRect.origin.x = knobRect.origin.x + floorf((knobRect.size.width - highlightRect.size.width) / 2);
  [_sliderImageMidHighlight drawInRect:highlightRect fromRect:NSZeroRect operation:kCGBlendModeSourceAtop fraction:1];
}

- (void)drawBarInside:(NSRect)aRect flipped:(BOOL)flipped {
  CGContextRef cx = [[NSGraphicsContext currentContext] graphicsPort];
  CGContextClearRect(cx, aRect);

  CGContextSetRGBFillColor(cx, 1, 1, 1, 0.25);
  for (NSInteger ix = 0; ix < self.numberOfTickMarks; ++ix) {
    CGRect rect = [self rectOfTickMarkAtIndex:ix];
    rect.origin.y = 0;
    rect.size.height = self.controlView.bounds.size.height;
    if (ix == 0 || ix == self.numberOfTickMarks - 1
        || (ix == self.numberOfTickMarks / 2 && (self.numberOfTickMarks % 2 == 1))) {
      rect.size.width += 1;
      rect.origin.x -= 0.5;
    }
    CGContextFillRect(cx, rect);
  }
  
  CGRect imageRect = aRect;
  imageRect.size.height = floor(_sliderBgImageLeft.size.height * 2);
  imageRect.origin.y = aRect.origin.y + floor((aRect.size.height - imageRect.size.height) / 2);
  
  NSDrawThreePartImage(imageRect, _sliderBgImageLeft, _sliderBgImageMid, _sliderBgImageRight, NO, kCGBlendModeSourceAtop, 1, NO);
}

- (NSRect)knobRectFlipped:(BOOL)flipped {
	NSRect rect = [super knobRectFlipped:flipped];
  CGRect knobRect = rect;
  knobRect.size.height = 32;
  knobRect.origin.y = rect.origin.y + floor((rect.size.height - knobRect.size.height) / 2);
  return knobRect;
}

@end

@implementation PHSlider

+ (void)initialize {
  [PHSlider setCellClass:[PHSliderCell class]];
}

@end
