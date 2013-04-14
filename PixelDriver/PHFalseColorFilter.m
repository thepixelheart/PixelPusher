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

#import "PHFalseColorFilter.h"

@implementation PHFalseColorFilter {
  CGFloat _color1Advance;
  CGFloat _color2Advance;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  _color1Advance += self.secondsSinceLastTick * 0.2;
  _color2Advance += self.secondsSinceLastTick * 0.1;

  [super renderBitmapInContext:cx size:size];
}

- (NSString *)filterName {
  return @"CIFalseColor";
}

- (id)color0Value {
  CGFloat offset = _color1Advance;
  CGFloat red = sin(offset) * 0.5 + 0.5;
  CGFloat green = cos(offset * 5 + M_PI_2) * 0.5 + 0.5;
  CGFloat blue = sin(offset * 13 - M_PI_4) * 0.5 + 0.5;
  return [CIColor colorWithRed:red green:green blue:blue];
}

- (id)color1Value {
  CGFloat offset = _color2Advance;
  CGFloat red = sin(offset) * 17 * 0.5 + 0.5;
  CGFloat green = cos(offset * 3 + M_PI_2) * 0.5 + 0.5;
  CGFloat blue = sin(offset * 11 - M_PI_4) * 0.5 + 0.5;
  return [CIColor colorWithRed:red green:green blue:blue];
}

- (NSString *)tooltipName {
  return @"False Color Filter";
}

@end
