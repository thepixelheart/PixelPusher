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

#import "PHSpectrumLinesAnimation.h"

static const NSTimeInterval kShiftPixelsInterval = 0.05;

@implementation PHSpectrumLinesAnimation {
  CGContextRef _linesContextRef;
  CGFloat _colorAdvance;
  CGFloat _scalers[48];
  NSTimeInterval _nextShiftTime;
}

- (void)dealloc {
  if (_linesContextRef) {
    CGContextRelease(_linesContextRef);
  }
}

- (id)init {
  if ((self = [super init])) {
    _linesContextRef = PHCreate8BitBitmapContextWithSize(CGSizeMake(kWallWidth, kWallHeight));
    for (NSInteger ix = 0; ix < kWallWidth; ++ix) {
      _scalers[ix] = 1000000;
    }
  }
  return self;
}

- (void)shiftPixelsUp {
  unsigned char* data = (unsigned char *)CGBitmapContextGetData(_linesContextRef);
  size_t bytesPerRow = CGBitmapContextGetBytesPerRow(_linesContextRef);

  for (NSInteger iy = 0; iy < kWallHeight - 1; ++iy) {
    memcpy(data + iy * bytesPerRow, data + (iy + 1) * bytesPerRow, bytesPerRow);
  }
  for (NSInteger ix = 0; ix < kWallWidth; ++ix) {
    NSInteger offset = ix * 4 + (kWallHeight - 1) * bytesPerRow;
    data[offset + 0] = data[offset + 0] * 0.75;
    data[offset + 1] = data[offset + 1] * 0.75;
    data[offset + 2] = data[offset + 2] * 0.75;
    data[offset + 3] = 255;
  }
}

- (void)tick {
  if ([NSDate timeIntervalSinceReferenceDate] >= _nextShiftTime) {
    [self shiftPixelsUp];

    _nextShiftTime = [NSDate timeIntervalSinceReferenceDate] + kShiftPixelsInterval;
  }

  _colorAdvance += self.secondsSinceLastTick * 0.2;

  unsigned char* data = (unsigned char *)CGBitmapContextGetData(_linesContextRef);
  size_t bytesPerRow = CGBitmapContextGetBytesPerRow(_linesContextRef);

  NSInteger numberOfSpectrumValues = (CGFloat)self.systemState.numberOfSpectrumValues * 0.7;
  float* spectrum = self.systemState.unifiedSpectrum;
  NSInteger numberOfValuesPerPixel = numberOfSpectrumValues / kWallWidth;

  for (NSInteger ix = 0; ix < kWallWidth; ++ix) {
    NSInteger offset = ix * 4 + (kWallHeight - 1) * bytesPerRow;

    CGFloat colorOffset = ((CGFloat)ix * 0.01) + _colorAdvance;
    CGFloat red = sin(colorOffset) * 0.5 + 0.5;
    CGFloat green = cos(colorOffset * 5 + M_PI_2) * 0.5 + 0.5;
    CGFloat blue = sin(colorOffset * 13 - M_PI_4) * 0.5 + 0.5;

    CGFloat amplitude = 0;

    NSInteger leftCol = numberOfValuesPerPixel * ix;
    NSInteger rightCol = numberOfValuesPerPixel * (ix + 1);
    for (NSInteger spectrumx = leftCol; spectrumx < rightCol; ++spectrumx) {
      amplitude += spectrum[spectrumx] * _scalers[ix];
    }
    amplitude /= (float)numberOfSpectrumValues;

    if (amplitude > 1) {
      _scalers[ix] = 1 / amplitude;
      amplitude = 1;
    }
    _scalers[ix] += 100;
    amplitude = MAX(0, MIN(1, amplitude));

    red *= amplitude;
    green *= amplitude;
    blue *= amplitude;

    data[offset + 0] = MAX(data[offset + 0], red * 255);
    data[offset + 1] = MAX(data[offset + 1], green * 255);
    data[offset + 2] = MAX(data[offset + 2], blue * 255);
    data[offset + 3] = 255;
  }
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  [self tick];

  CGImageRef imageRef = CGBitmapContextCreateImage(_linesContextRef);
  CGContextDrawImage(cx, CGRectMake(0, 0, size.width, size.height), imageRef);
  CGImageRelease(imageRef);
}

- (NSString *)tooltipName {
  return @"Spectrum Lines";
}

@end
