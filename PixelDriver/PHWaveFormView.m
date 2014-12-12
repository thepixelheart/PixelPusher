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

#import "PHSystemState.h"
#import "PHFMODRecorder.h"
#import "AppDelegate.h"

@implementation PHWaveFormView

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size driver:(PHSystemState *)driver systemTick:(PHSystemTick *)systemTick {
  float* waveData = nil;
  if (self.audioChannel == PHAudioChannelLeft) {
    waveData = driver.leftWaveData;
  } else if (self.audioChannel == PHAudioChannelRight) {
    waveData = driver.rightWaveData;
  } else if (self.audioChannel == PHAudioChannelUnified) {
    waveData = driver.unifiedWaveData;
  } else if (self.audioChannel == PHAudioChannelDifference) {
    waveData = driver.differenceWaveData;
  }
  if (nil == waveData) {
    return;
  }

  NSInteger numberOfWaveDataValues = driver.numberOfWaveDataValues;

  CGContextBeginPath(cx);
  CGContextMoveToPoint(cx, 0, size.height / 2);
  CGContextSetInterpolationQuality(cx, kCGInterpolationNone);

  CGFloat scale = 2;
  int bucketSize = floorf(((CGFloat)numberOfWaveDataValues) / size.width) / scale;
  for (int ix = 0; ix < size.width * scale; ++ix) {
    CGFloat total = 0;
    for (int iy = ix * bucketSize; iy < (ix + 1) * bucketSize; ++iy) {
      total += waveData[iy];
    }
    total /= (CGFloat)bucketSize;
    CGContextAddLineToPoint(cx, (CGFloat)ix / scale, total * size.height / 2 + size.height / 2);
  }

  NSColor* color = [NSColor colorWithDeviceRed:0.5 green:0.5 blue:0.5 alpha:1];
  CGContextSetStrokeColorWithColor(cx, color.CGColor);

  CGContextStrokePath(cx);
}

- (double)threadPriority {
  return 0.2;
}

@end
