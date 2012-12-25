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

#import "PHWaveFormView.h"

#import "PHAnimationDriver.h"
#import "PHFMODRecorder.h"
#import "AppDelegate.h"

@implementation PHWaveFormView

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size driver:(PHAnimationDriver *)driver {
  float* waveData = nil;
  if (self.audioChannel == PHAudioChannelLeft) {
    waveData = driver.leftWaveData;
  } else if (self.audioChannel == PHAudioChannelRight) {
    waveData = driver.rightWaveData;
  } else if (self.audioChannel == PHAudioChannelUnified) {
    waveData = driver.unifiedWaveData;
  }
  if (nil == waveData) {
    NSLog(@"No wave data found");
    return;
  }

  NSInteger numberOfWaveDataValues = driver.numberOfWaveDataValues;

  CGRect bounds = CGRectMake(0, 0, size.width, size.height);
  CGContextSetRGBFillColor(cx, (float)0xED / 255.f, (float)0xED / 255.f, (float)0xED / 255.f, 1);
  CGContextFillRect(cx, bounds);

  CGContextBeginPath(cx);
  CGContextMoveToPoint(cx, 0, size.height / 2);
  CGContextSetInterpolationQuality(cx, kCGInterpolationNone);

  for (int ix = 0; ix < numberOfWaveDataValues; ++ix) {
    CGFloat pointX = (CGFloat)(ix * size.width) / numberOfWaveDataValues;
    CGContextAddLineToPoint(cx, pointX, waveData[ix] * size.height / 2 + size.height / 2);
  }

  NSColor* color = [NSColor colorWithDeviceRed:0.5 green:0.5 blue:0.5 alpha:1];
  CGContextSetStrokeColorWithColor(cx, color.CGColor);

  CGContextStrokePath(cx);
}

- (double)threadPriority {
  return 0.2;
}

@end
