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

#import "PHCheckerboardGeneratorFilter.h"

@implementation PHCheckerboardGeneratorFilter {
  CGFloat _color1Advance;
  CGFloat _color2Advance;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  _color1Advance += self.secondsSinceLastTick * 0.1;
  _color2Advance += self.secondsSinceLastTick * 0.3;

  [super renderBitmapInContext:cx size:size];
}

- (NSString *)filterName {
  return @"CICheckerboardGenerator";
}

- (BOOL)isGenerator {
  return YES;
}

- (CIImage *)imageValueWithContext:(CGContextRef)cx {
  return nil;
}

- (id)centerValue {
  return [self wallCenterValue];
}

- (id)color0Value {
  CGFloat offset = _color1Advance;
  CGFloat red = sin(offset * 7) * 0.3 + 0.7;
  CGFloat green = cos(offset * 5 + M_PI_2) * 0.3 + 0.7;
  CGFloat blue = sin(offset * 13 - M_PI_4) * 0.3 + 0.7;
  return [CIColor colorWithRed:red green:green blue:blue];
}

- (id)color1Value {
  CGFloat offset = _color2Advance;
  CGFloat red = sin(offset) * 17 * 0.3 + 0.7;
  CGFloat green = cos(offset * 3 + M_PI_2) * 0.3 + 0.7;
  CGFloat blue = sin(offset * 11 - M_PI_4) * 0.3 + 0.7;
  return [CIColor colorWithRed:red green:green blue:blue];
}

- (id)widthValue {
  return @(10);
}

- (id)sharpnessValue {
  return @(self.bassDegrader.value);
}

- (NSImage *)previewImage {
  return [NSImage imageNamed:@"checkerboardgenerator"];
}

- (NSString *)tooltipName {
  return @"Checkerboard Generator Filter";
}

@end
