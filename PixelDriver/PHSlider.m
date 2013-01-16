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
}

- (id)init {
  if ((self = [super init])) {
    _sliderImageLeft = [NSImage imageNamed:@"sliderLxx"];
    _sliderImageMid = [NSImage imageNamed:@"sliderxMx"];
    _sliderImageMidHighlight = [NSImage imageNamed:@"sliderxMxHighlight"];
    _sliderImageRight = [NSImage imageNamed:@"sliderxxR"];
  }
  return self;
}

- (void)drawKnob:(NSRect)knobRect {
  NSDrawThreePartImage(knobRect, _sliderImageLeft, _sliderImageMid, _sliderImageRight, NO, NSCompositeCopy, 1, NO);
  CGRect highlightRect = knobRect;
  highlightRect.size.width = _sliderImageMidHighlight.size.width;
  highlightRect.origin.x = knobRect.origin.x + floorf((knobRect.size.width - highlightRect.size.width) / 2);
  [_sliderImageMidHighlight drawInRect:highlightRect fromRect:NSZeroRect operation:NSCompositeCopy fraction:1];
}

- (NSRect)knobRectFlipped:(BOOL)flipped {
	NSRect rect = [super knobRectFlipped:flipped];
  rect = CGRectInset(rect, 3, -10);
  rect.size.height++;
  return rect;
}

@end

@implementation PHSlider

+ (void)initialize {
  [PHSlider setCellClass:[PHSliderCell class]];
}

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    self.knobThickness = 50;
  }
  return self;
}

@end
