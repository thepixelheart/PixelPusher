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
  [[NSColor colorWithDeviceRed:(float)0xED / 255.f green:(float)0xED / 255.f blue:(float)0xED / 255.f alpha:1] set];
  CGContextFillRect(cx, bounds);

  CGFloat max = 0;
  for (int ix = 30; ix < numberOfSpectrumValues; ++ix) {
    max = MAX(max, spectrum[ix]);
  }
  if (max > 0) {
    int windowSize = numberOfSpectrumValues / size.width;
    float nyquist = 44100 / 2;
    float bandHz = nyquist / (float)numberOfSpectrumValues;

    for (int ix = 0; ix < size.width; ++ix) {
      float total = 0;

      for (int is = ix * windowSize; is < (ix + 1) * windowSize; ++is) {
        float decibels = 100.0f * log10f(spectrum[is] + 1.0f);
        total += decibels;
      }
      float hz = ((float)ix / size.width) * (float)numberOfSpectrumValues * bandHz;
      if (hz >= 0 && hz < 100) {
        [[NSColor redColor] set];
      } else {
        [[NSColor darkGrayColor] set];
      }
      float average = total / (float)windowSize;
      CGRect rect = CGRectMake(ix, 0, 1, average * self.bounds.size.height);
      CGContextFillRect(cx, rect);
    }
  }
}

@end
