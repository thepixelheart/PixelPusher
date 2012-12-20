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

// Breakdown of electronic music frequencies
// http://howtomakeelectronicmusic.com/wp-content/uploads/2011/07/FM_clubmix_dsktp.jpg
typedef struct {
  float start;
  float end;
  float center;
} PHFrequencyRange;

static const PHFrequencyRange kSubBassRange = {0, 100, -1};
static const PHFrequencyRange kHihatRange = {11500, 14000, -1};
static const PHFrequencyRange kVocalRange = {300, 3400, -1};
static const PHFrequencyRange kSnareRange = {500, 6000, 1000};

@implementation PHAnimationDriver {
  CGFloat _subBassScale;
  CGFloat _hihatScale;
  CGFloat _vocalScale;
  CGFloat _snareScale;
}

- (id)init {
  if ((self = [super init])) {
    _subBassScale = 50;
    _hihatScale = 1200;
    _vocalScale = 400;
    _snareScale = 400;
  }
  return self;
}

- (float)amplitudeOfSpectrumWithRange:(PHFrequencyRange)range scale:(CGFloat *)scale {
  float nyquist = 44100 / 2;
  float bandHz = nyquist / (float)_numberOfSpectrumValues;

  float amplitude = 0;
  NSInteger start = range.start / bandHz;
  NSInteger end = range.end / bandHz;
  for (NSInteger ix = start; ix < end; ++ix) {
    float decibels = log10f(_spectrum[ix] + 1.0f) * (*scale);
    if (range.center >= 0) {
      float hz = (float)ix * bandHz;
      float distanceRatio;
      if (hz < range.center) {
        distanceRatio = (hz - range.start) / (range.center - range.start);
      } else {
        distanceRatio = (range.end - hz) / (range.end - range.center);
      }
      float scale = sinf((distanceRatio - 0.5) * M_PI) / 2.f + 0.5f;
      decibels *= scale;
    }
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
  _hihatAmplitude = [self amplitudeOfSpectrumWithRange:kHihatRange scale:&_hihatScale];
  _vocalAmplitude = [self amplitudeOfSpectrumWithRange:kVocalRange scale:&_vocalScale];
  _snareAmplitude = [self amplitudeOfSpectrumWithRange:kSnareRange scale:&_snareScale];
}

@end
