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

static const NSInteger kNumberOfSpectrumValues = (1 << 12);
static const CGFloat kMaxUsefulSpectrumValues = (1 << 11) + 600;

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
      _listening = NO;
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
    _channel->setVolume(1);
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

  FMOD_RESULT result = _system->setDriver(_playbackDriverIndex);

  if (_listening) {
    [self stopListening];
    if (result == FMOD_OK) {
      [self toggleListening];
    }
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

- (NSInteger)numberOfSpectrumValues {
  return kMaxUsefulSpectrumValues;
}

- (float *)leftSpectrum {
  memset(_leftSpectrum, 0, sizeof(float) * kNumberOfSpectrumValues);
  _channel->getSpectrum(_leftSpectrum, kNumberOfSpectrumValues, 0, FMOD_DSP_FFT_WINDOW_BLACKMANHARRIS);
  return _leftSpectrum;
}

- (float *)rightSpectrum {
  memset(_rightSpectrum, 0, sizeof(float) * kNumberOfSpectrumValues);
  _channel->getSpectrum(_rightSpectrum, kNumberOfSpectrumValues, 1, FMOD_DSP_FFT_WINDOW_BLACKMANHARRIS);
  return _rightSpectrum;
}

@end
