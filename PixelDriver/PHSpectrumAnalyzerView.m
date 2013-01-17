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
#import "PHAnimationDriver.h"
#import "PHBitmapPipeline.h"
#import "PHDisplayLink.h"
#import "Utilities.h"

@implementation PHSpectrumAnalyzerView

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size driver:(PHAnimationDriver *)driver systemTick:(PHSystemTick *)systemTick {
  CGRect bounds = CGRectMake(0, 0, size.width, size.height);
  CGContextSetRGBFillColor(cx, (float)0xED / 255.f, (float)0xED / 255.f, (float)0xED / 255.f, 1);
  CGContextFillRect(cx, bounds);

  float* spectrum = nil;
  if (self.audioChannel == PHAudioChannelLeft) {
    spectrum = driver.leftSpectrum;
  } else if (self.audioChannel == PHAudioChannelRight) {
    spectrum = driver.rightSpectrum;
  } else if (self.audioChannel == PHAudioChannelUnified) {
    spectrum = driver.unifiedSpectrum;
  }
  if (nil == spectrum) {
    NSLog(@"No spectrum found.");
    return;
  }

  NSInteger numberOfSpectrumValues = driver.numberOfSpectrumValues;
  CGFloat max = 0;
  for (int ix = 30; ix < numberOfSpectrumValues; ++ix) {
    max = MAX(max, spectrum[ix]);
  }
  if (max > 0) {
    int windowSize = numberOfSpectrumValues / size.width;
    //float nyquist = 44100 / 2;
    //float bandHz = nyquist / (float)numberOfSpectrumValues;

    NSColor* color = [NSColor colorWithDeviceRed:0.5 green:0.5 blue:0.5 alpha:1];
    CGContextSetFillColorWithColor(cx, color.CGColor);
    for (int ix = 0; ix < size.width; ++ix) {
      float total = 0;

      for (int is = ix * windowSize; is < (ix + 1) * windowSize; ++is) {
        float decibels = 100.0f * log10f(spectrum[is] + 1.0f);
        total += decibels;
      }
      //float hz = ((float)ix / size.width) * (float)numberOfSpectrumValues * bandHz;
      float average = total / (float)windowSize;
      CGRect rect = CGRectMake(ix, 0, 1, average * self.bounds.size.height);
      CGContextFillRect(cx, rect);
    }
  }
}

- (double)threadPriority {
  return 0.2;
}

@end
