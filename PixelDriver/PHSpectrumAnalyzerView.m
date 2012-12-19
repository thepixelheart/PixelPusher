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

#import "PHSpectrumAnalyzerView.h"

#import "AppDelegate.h"
#import "PHBitmapPipeline.h"
#import "PHDisplayLink.h"
#import "Utilities.h"

@implementation PHSpectrumAnalyzerView

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size spectrum:(float *)spectrum numberOfSpectrumValues:(NSInteger)numberOfSpectrumValues {
  CGRect bounds = CGRectMake(0, 0, size.width, size.height);
  [[NSColor blackColor] set];
  CGContextFillRect(cx, bounds);

  [[NSColor colorWithDeviceRed:1 green:1 blue:1 alpha:1] set];
  CGFloat colWidth = size.width / (CGFloat)numberOfSpectrumValues;
  CGFloat max = 0;
  for (int ix = 30; ix < numberOfSpectrumValues; ++ix) {
    max = MAX(max, spectrum[ix]);
  }
  if (max > 0) {
    for (int ix = 0; ix < numberOfSpectrumValues; ++ix) {
      CGRect rect = CGRectMake(colWidth * ix, 0, colWidth, (spectrum[ix] / 0.002) * self.bounds.size.height);
      CGContextFillRect(cx, rect);
    }
  }
}

@end
