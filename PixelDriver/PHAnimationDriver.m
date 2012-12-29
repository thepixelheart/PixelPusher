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

#import "PHFMODRecorder.h"

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
static const PHFrequencyRange kPitchDetectionRange = {200, 8000, -1};

static const char *note[PHPitch_Count] = {
  "C 0", "C#0", "D 0", "D#0", "E 0", "F 0", "F#0", "G 0", "G#0", "A 0", "A#0", "B 0",
  "C 1", "C#1", "D 1", "D#1", "E 1", "F 1", "F#1", "G 1", "G#1", "A 1", "A#1", "B 1",
  "C 2", "C#2", "D 2", "D#2", "E 2", "F 2", "F#2", "G 2", "G#2", "A 2", "A#2", "B 2",
  "C 3", "C#3", "D 3", "D#3", "E 3", "F 3", "F#3", "G 3", "G#3", "A 3", "A#3", "B 3",
  "C 4", "C#4", "D 4", "D#4", "E 4", "F 4", "F#4", "G 4", "G#4", "A 4", "A#4", "B 4",
  "C 5", "C#5", "D 5", "D#5", "E 5", "F 5", "F#5", "G 5", "G#5", "A 5", "A#5", "B 5",
  "C 6", "C#6", "D 6", "D#6", "E 6", "F 6", "F#6", "G 6", "G#6", "A 6", "A#6", "B 6",
  "C 7", "C#7", "D 7", "D#7", "E 7", "F 7", "F#7", "G 7", "G#7", "A 7", "A#7", "B 7",
  "C 8", "C#8", "D 8", "D#8", "E 8", "F 8", "F#8", "G 8", "G#8", "A 8", "A#8", "B 8",
  "C 9", "C#9", "D 9", "D#9", "E 9", "F 9", "F#9", "G 9", "G#9", "A 9", "A#9", "B 9"
};

static const float notefreq[PHPitch_Count] = {
  16.35f,   17.32f,   18.35f,   19.45f,    20.60f,    21.83f,    23.12f,    24.50f,    25.96f,    27.50f,    29.14f,    30.87f,
  32.70f,   34.65f,   36.71f,   38.89f,    41.20f,    43.65f,    46.25f,    49.00f,    51.91f,    55.00f,    58.27f,    61.74f,
  65.41f,   69.30f,   73.42f,   77.78f,    82.41f,    87.31f,    92.50f,    98.00f,   103.83f,   110.00f,   116.54f,   123.47f,
  130.81f,  138.59f,  146.83f,  155.56f,   164.81f,   174.61f,   185.00f,   196.00f,   207.65f,   220.00f,   233.08f,   246.94f,
  261.63f,  277.18f,  293.66f,  311.13f,   329.63f,   349.23f,   369.99f,   392.00f,   415.30f,   440.00f,   466.16f,   493.88f,
  523.25f,  554.37f,  587.33f,  622.25f,   659.26f,   698.46f,   739.99f,   783.99f,   830.61f,   880.00f,   932.33f,   987.77f,
  1046.50f, 1108.73f, 1174.66f, 1244.51f,  1318.51f,  1396.91f,  1479.98f,  1567.98f,  1661.22f,  1760.00f,  1864.66f,  1975.53f,
  2093.00f, 2217.46f, 2349.32f, 2489.02f,  2637.02f,  2793.83f,  2959.96f,  3135.96f,  3322.44f,  3520.00f,  3729.31f,  3951.07f,
  4186.01f, 4434.92f, 4698.64f, 4978.03f,  5274.04f,  5587.65f,  5919.91f,  6271.92f,  6644.87f,  7040.00f,  7458.62f,  7902.13f,
  8372.01f, 8869.84f, 9397.27f, 9956.06f, 10548.08f, 11175.30f, 11839.82f, 12543.85f, 13289.75f, 14080.00f, 14917.24f, 15804.26f
};

@implementation PHAnimationDriver

- (id)init {
  if ((self = [super init])) {
    [self resetScales];
  }
  return self;
}

- (float)nyquist {
  // The sample rate divided by two. This is the range of the spectrum's values.
  return 44100 / 2;
}

- (float)hzPerSpectrumValue {
  return [self nyquist] / (float)_numberOfSpectrumValues;
}

- (float)hzPerHighResSpectrumValue {
  return [self nyquist] / (float)_numberOfHighResSpectrumValues;
}

- (float)amplitudeOfSpectrumWithRange:(PHFrequencyRange)range scale:(CGFloat *)scale {
  float hzPerSpectrumValue = [self hzPerSpectrumValue];

  float amplitude = 0;
  NSInteger start = range.start / hzPerSpectrumValue;
  NSInteger end = range.end / hzPerSpectrumValue;
  for (NSInteger ix = start; ix < end; ++ix) {
    float decibels = log10f(_unifiedSpectrum[ix] + 1.0f);

    if (range.center >= 0) {
      float hz = (float)ix * hzPerSpectrumValue;
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
  float scaledAmplitude = amplitude * (*scale);
  if (scaledAmplitude > 1) {
    *scale = 1 / amplitude;
    scaledAmplitude = 1;
  }
  return scaledAmplitude;
}

- (void)updateWithAudioRecorder:(PHFMODRecorder *)audio motes:(NSArray *)motes {
  [self updateSpectrumWithAudio:audio];
  [self updateHighResSpectrumWithAudio:audio];
  [self updateWaveWithAudio:audio];
  _motes = [motes copy];
}

- (void)updateSpectrumWithAudio:(PHFMODRecorder *)audio {
  [audio getSpectrumLeft:&_leftSpectrum right:&_rightSpectrum unified:&_unifiedSpectrum];
  _numberOfSpectrumValues = audio.numberOfSpectrumValues;

  _subBassAmplitude = [self amplitudeOfSpectrumWithRange:kSubBassRange scale:&_subBassScale];
  _hihatAmplitude = [self amplitudeOfSpectrumWithRange:kHihatRange scale:&_hihatScale];
  _vocalAmplitude = [self amplitudeOfSpectrumWithRange:kVocalRange scale:&_vocalScale];
  _snareAmplitude = [self amplitudeOfSpectrumWithRange:kSnareRange scale:&_snareScale];
}

- (void)updateHighResSpectrumWithAudio:(PHFMODRecorder *)audio {
  [audio getHighResSpectrumLeft:&_highResLeftSpectrum right:&_highResRightSpectrum unified:&_highResUnifiedSpectrum];
  _numberOfHighResSpectrumValues = audio.numberOfHighResSpectrumValues;

  // First find the loudest frequency, ignoring the bass.
  float max = 0;
  NSInteger indexOfMax = 0;

  float hzPerSpectrumValue = [self hzPerHighResSpectrumValue];
  NSInteger leftEdge = floorf(kPitchDetectionRange.start / hzPerSpectrumValue);
  NSInteger rightEdge = floorf(kPitchDetectionRange.end / hzPerSpectrumValue);

  for (NSInteger ix = MIN(_numberOfHighResSpectrumValues, leftEdge);
       ix < MIN(_numberOfHighResSpectrumValues, rightEdge);
       ++ix) {
    if (_highResUnifiedSpectrum[ix] > 0.01f && _highResUnifiedSpectrum[ix] > max) {
      max = _highResUnifiedSpectrum[ix];
      indexOfMax = ix;
    }
  }

  float hzOfMaxValue = (float)indexOfMax * hzPerSpectrumValue;
  NSInteger indexOfNote = 0;
  for (NSInteger ix = 0; ix < PHPitch_Count; ++ix) {
    if (hzOfMaxValue >= notefreq[ix] && hzOfMaxValue < notefreq[ix + 1]) {
      if (fabs(hzOfMaxValue - notefreq[ix]) < fabs(hzOfMaxValue - notefreq[ix + 1])) {
        indexOfNote = ix;
      } else {
        indexOfNote = ix + 1;
      }
      break;
    }
  }

  if (indexOfNote > 0) {
    _dominantPitch = (PHPitch)indexOfNote;
  } else {
    _dominantPitch = PHPitch_Unknown;
  }
}

- (void)updateWaveWithAudio:(PHFMODRecorder *)audio {
  [audio getWaveLeft:&_leftWaveData right:&_rightWaveData unified:&_unifiedWaveData difference:&_differenceWaveData];
  _numberOfWaveDataValues = audio.numberOfWaveDataValues;
}

- (NSString *)nameOfPitch:(PHPitch)pitch {
  if (pitch < PHPitch_Count) {
    return [NSString stringWithFormat:@"%s", note[pitch]];
  }
  return nil;
}

- (void)resetScales {
  _subBassScale = 200;
  _hihatScale = 2000;
  _vocalScale = 800;
  _snareScale = 1800;
}

@end
