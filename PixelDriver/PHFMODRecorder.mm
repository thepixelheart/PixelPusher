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

#import "PHFMODRecorder.h"

#import "fmod.hpp"
#import "fmod_errors.h"

static const NSInteger kNumberOfSpectrumValues = (1 << 11);
static const NSInteger kNumberOfHighResSpectrumValues = (1 << 13);
static const NSInteger kNumberOfWaveDataValues = 16384;

#define INITCHECKFMODRESULT(result) do {\
  if (result != FMOD_OK) { \
    NSLog(@"Failed to initialize FMOD recorder: %s", FMOD_ErrorString(result)); \
    self = nil; \
    return self; \
  } \
} while(0)

static NSString* const kPlaybackDriverNameUserDefaultsKey = @"kPlaybackDriverNameUserDefaultsKey";
static NSString* const kRecordingDriverNameUserDefaultsKey = @"kRecordingDriverNameUserDefaultsKey";
static const unsigned int kRecordingDuration = 60 * 5;

@implementation PHFMODRecorder {
  FMOD::System* _system;
  FMOD::Sound* _sound;
  FMOD::Channel* _channel;
  BOOL _listening;

  float _leftSpectrum[kNumberOfSpectrumValues];
  float _rightSpectrum[kNumberOfSpectrumValues];
  float _unifiedSpectrum[kNumberOfSpectrumValues];

  float _leftHighResSpectrum[kNumberOfHighResSpectrumValues];
  float _rightHighResSpectrum[kNumberOfHighResSpectrumValues];
  float _unifiedHighResSpectrum[kNumberOfHighResSpectrumValues];

  float _leftWaveData[kNumberOfWaveDataValues];
  float _rightWaveData[kNumberOfWaveDataValues];
  float _unifiedWaveData[kNumberOfWaveDataValues];
  float _differenceWaveData[kNumberOfWaveDataValues];
}

- (void)dealloc {
  if (nil != _sound) {
    _sound->release();
  }
  if (nil != _system) {
    _system->release();
  }
}

- (id)init {
  if ((self = [super init])) {
    _volume = 1;

    FMOD_RESULT result = FMOD::System_Create(&_system);
    INITCHECKFMODRESULT(result);

    unsigned int version;
    result = _system->getVersion(&version);
    INITCHECKFMODRESULT(result);

    if (version < FMOD_VERSION) {
      printf("Using an old version of FMOD %08x. This program requires %08x\n", version, FMOD_VERSION);
      self = nil;
      return self;
    }


    // Playback drivers.

    int numberOfDrivers = 0;
    result = _system->getNumDrivers(&numberOfDrivers);
    INITCHECKFMODRESULT(result);

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString* playbackDriverName = [prefs valueForKey:kPlaybackDriverNameUserDefaultsKey];

    NSMutableArray *driverNames = [NSMutableArray array];
    for (int ix = 0; ix < numberOfDrivers; ++ix) {
      char name[256];

      result = _system->getDriverInfo(ix, name, 256, 0);
      INITCHECKFMODRESULT(result);
      NSString* driverName = [NSString stringWithCString:name encoding:NSASCIIStringEncoding];
      if ([playbackDriverName isEqualToString:driverName]) {
        _playbackDriverIndex = ix;
      }
      [driverNames addObject:driverName];
    }
    _playbackDriverNames = [driverNames copy];

    if (nil == playbackDriverName) {
      _playbackDriverIndex = 0;
      [prefs setValue:_recordDriverNames[0] forKey:kPlaybackDriverNameUserDefaultsKey];
    }

    result = _system->setDriver(_playbackDriverIndex);
    INITCHECKFMODRESULT(result);


    // Recording drivers.

    numberOfDrivers = 0;
    result = _system->getRecordNumDrivers(&numberOfDrivers);
    INITCHECKFMODRESULT(result);

    NSString* recordingDriverName = [prefs valueForKey:kRecordingDriverNameUserDefaultsKey];

    driverNames = [NSMutableArray array];
    for (int ix = 0; ix < numberOfDrivers; ++ix) {
      char name[256];

      result = _system->getRecordDriverInfo(ix, name, 256, 0);
      INITCHECKFMODRESULT(result);
      NSString* driverName = [NSString stringWithCString:name encoding:NSASCIIStringEncoding];
      if ([recordingDriverName isEqualToString:driverName]) {
        _recordDriverIndex = ix;
      }
      [driverNames addObject:driverName];
    }
    _recordDriverNames = [driverNames copy];

    if (nil == recordingDriverName) {
      _recordDriverIndex = 0;
      [prefs setValue:_recordDriverNames[0] forKey:kRecordingDriverNameUserDefaultsKey];
    }
    [prefs removeObjectForKey:kRecordingDriverNameUserDefaultsKey];
    [prefs removeObjectForKey:kPlaybackDriverNameUserDefaultsKey];

    result = _system->init(8, FMOD_INIT_NORMAL, 0);
    INITCHECKFMODRESULT(result);

    FMOD_CREATESOUNDEXINFO exinfo;
    memset(&exinfo, 0, sizeof(FMOD_CREATESOUNDEXINFO));

    exinfo.cbsize = sizeof(FMOD_CREATESOUNDEXINFO);
    exinfo.numchannels = 2;
    exinfo.defaultfrequency = 44100;
    exinfo.format = FMOD_SOUND_FORMAT_PCM16;
    exinfo.length = exinfo.defaultfrequency * sizeof(short) * exinfo.numchannels * kRecordingDuration;

    result = _system->createSound(0, FMOD_2D | FMOD_SOFTWARE | FMOD_OPENUSER, &exinfo, &_sound);
    INITCHECKFMODRESULT(result);
  }
  return self;
}

- (BOOL)isListening {
  return _listening;
}

- (void)toggleListening {
  _listening = !_listening;

  if (_listening) {
    FMOD_RESULT result = _system->recordStart(_recordDriverIndex, _sound, YES);
    if (result == FMOD_OK) {
      usleep(25 * 1000);
      [self startPlaying];
    } else {
      [self stopListening];
    }

  } else {
    [self stopListening];
  }
}

- (void)startPlaying {
  if (_listening) {
    if (_channel) {
      _channel->stop();
      _channel = nil;
    }

    _sound->setMode(FMOD_LOOP_NORMAL);
    FMOD_RESULT result = _system->playSound(FMOD_CHANNEL_REUSE, _sound, false, &_channel);
    _channel->setVolume(_volume);
    if (result != FMOD_OK) {
      [self stopListening];
    }
  }
}

- (void)stopListening {
  _listening = NO;
  if (_channel) {
    _channel->stop();
    _channel = nil;
  }
  _system->recordStop(_recordDriverIndex);
}

- (void)setPlaybackDriverIndex:(int)playbackDriverIndex {
  _playbackDriverIndex = playbackDriverIndex;

  NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
  [prefs setValue:[_playbackDriverNames objectAtIndex:_playbackDriverIndex]
           forKey:kPlaybackDriverNameUserDefaultsKey];
  [prefs synchronize];

  _system->setDriver(_playbackDriverIndex);

  if (_listening) {
    [self stopListening];
    [self toggleListening];
  }
}

- (void)setRecordDriverIndex:(int)recordDriverIndex {
  _recordDriverIndex = recordDriverIndex;

  NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
  [prefs setValue:[_recordDriverNames objectAtIndex:_recordDriverIndex]
           forKey:kRecordingDriverNameUserDefaultsKey];
  [prefs synchronize];

  if (_listening) {
    [self stopListening];
    [self toggleListening];
  }
}

- (void)getSpectrumLeft:(float **)left right:(float **)right unified:(float **)unified {
  memset(_leftSpectrum, 0, sizeof(float) * kNumberOfSpectrumValues);
  memset(_rightSpectrum, 0, sizeof(float) * kNumberOfSpectrumValues);

  _channel->getSpectrum(_leftSpectrum, kNumberOfSpectrumValues, 0, FMOD_DSP_FFT_WINDOW_TRIANGLE);
  _channel->getSpectrum(_rightSpectrum, kNumberOfSpectrumValues, 1, FMOD_DSP_FFT_WINDOW_TRIANGLE);

  for (NSInteger ix = 0; ix < kNumberOfSpectrumValues; ++ix) {
    _unifiedSpectrum[ix] = (_leftSpectrum[ix] + _rightSpectrum[ix]) / 2;
  }

  *left = _leftSpectrum;
  *right = _rightSpectrum;
  *unified = _unifiedSpectrum;
}

- (NSInteger)numberOfSpectrumValues {
  return kNumberOfSpectrumValues;
}

- (void)getHighResSpectrumLeft:(float **)left right:(float **)right unified:(float **)unified {
  memset(_leftHighResSpectrum, 0, sizeof(float) * kNumberOfHighResSpectrumValues);
  memset(_rightHighResSpectrum, 0, sizeof(float) * kNumberOfHighResSpectrumValues);

  _channel->getSpectrum(_leftHighResSpectrum, kNumberOfHighResSpectrumValues, 0, FMOD_DSP_FFT_WINDOW_TRIANGLE);
  _channel->getSpectrum(_rightHighResSpectrum, kNumberOfHighResSpectrumValues, 1, FMOD_DSP_FFT_WINDOW_TRIANGLE);

  for (NSInteger ix = 0; ix < kNumberOfHighResSpectrumValues; ++ix) {
    _unifiedHighResSpectrum[ix] = (_leftHighResSpectrum[ix] + _rightHighResSpectrum[ix]) / 2;
  }

  *left = _leftHighResSpectrum;
  *right = _rightHighResSpectrum;
  *unified = _unifiedHighResSpectrum;
}

- (NSInteger)numberOfHighResSpectrumValues {
  return kNumberOfHighResSpectrumValues;
}

- (void)getWaveLeft:(float **)left right:(float **)right unified:(float **)unified difference:(float **)difference {
  memset(_leftWaveData, 0, sizeof(float) * kNumberOfWaveDataValues);
  memset(_rightWaveData, 0, sizeof(float) * kNumberOfWaveDataValues);

  _channel->getWaveData(_leftWaveData, kNumberOfWaveDataValues, 0);
  _channel->getWaveData(_rightWaveData, kNumberOfWaveDataValues, 1);

  for (NSInteger ix = 0; ix < kNumberOfWaveDataValues; ++ix) {
    _unifiedWaveData[ix] = (_leftWaveData[ix] + _rightWaveData[ix]) / 2;
    _differenceWaveData[ix] = fabsf(fabsf(_leftWaveData[ix]) - fabsf(_rightWaveData[ix]));
  }

  *left = _leftWaveData;
  *right = _rightWaveData;
  *unified = _unifiedWaveData;
  *difference = _differenceWaveData;
}

- (NSInteger)numberOfWaveDataValues {
  return kNumberOfWaveDataValues;
}

- (void)setVolume:(float)volume {
  _volume = volume;

  if (nil != _channel) {
    _channel->setVolume(_volume);
  }
}

@end
