//
// Copyright 2012 Jeff Verkoeyen, Greg Marra
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

#import "PHLevelsHorizAnimation.h"

@implementation PHLevelsHorizAnimation

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  if (self.driver.unifiedSpectrum) {
    int wallQuartile = kWallHeight / 4;

    CGContextSetRGBFillColor(cx, 1, 0, 0, 1);
    CGContextFillRect(cx, CGRectMake(0, 0, self.bassDegrader.value * size.width, wallQuartile));

    CGContextSetRGBFillColor(cx, 0, 1, 0, 1);
    CGContextFillRect(cx, CGRectMake(0, wallQuartile, self.hihatDegrader.value * size.width, wallQuartile));

    CGContextSetRGBFillColor(cx, 0, 0, 1, 1);
    CGContextFillRect(cx, CGRectMake(0, 2 * wallQuartile, self.vocalDegrader.value * size.width, wallQuartile));

    CGContextSetRGBFillColor(cx, 1, 0, 1, 1);
    CGContextFillRect(cx, CGRectMake(0, 3 * wallQuartile, self.snareDegrader.value * size.width, wallQuartile));
  }
}

- (NSString *)tooltipName {
  return @"Horizontal Levels";
}

@end
