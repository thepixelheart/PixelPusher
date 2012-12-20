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

#import "PHAnimationDriver.h"

static const NSRange kSubBassRange = {0, 100};
static const NSRange khihatRange = {11500, 14000 - 11500};
static const NSRange kVocalRange = {300, 3400 - 300};

@implementation PHAnimationDriver {
  CGFloat _subBassScale;
  CGFloat _hihatScale;
  CGFloat _vocalScale;
}

- (id)init {
  if ((self = [super init])) {
    _subBassScale = 50;
    _hihatScale = 1200;
    _vocalScale = 400;
  }
  return self;
}

- (float)amplitudeOfSpectrumWithRange:(NSRange)range scale:(CGFloat *)scale {
  float nyquist = 44100 / 2;
  float bandHz = nyquist / (float)_numberOfSpectrumValues;

  float amplitude = 0;
  NSInteger start = range.location / bandHz;
  NSInteger end = NSMaxRange(range) / bandHz;
  for (NSInteger ix = start; ix < end; ++ix) {
    float decibels = log10f(_spectrum[ix] + 1.0f) * (*scale);
    amplitude += decibels;
  }
  amplitude /= (float)(end - start);
  if (amplitude > 1) {
    amplitude = 1;
    *scale -= 1;
  }
  return amplitude;
}

- (void)setSpectrum:(float *)spectrum numberOfValues:(NSInteger)numberOfValues {
  _spectrum = spectrum;
  _numberOfSpectrumValues = numberOfValues;

  _subBassAmplitude = [self amplitudeOfSpectrumWithRange:kSubBassRange scale:&_subBassScale];
  _hihatAmplitude = [self amplitudeOfSpectrumWithRange:khihatRange scale:&_hihatScale];
  _vocalAmplitude = [self amplitudeOfSpectrumWithRange:kVocalRange scale:&_vocalScale];
}

@end
