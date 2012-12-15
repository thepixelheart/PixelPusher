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

#define INITCHECKFMODRESULT(result) do {\
  if (result != FMOD_OK) { \
    NSLog(@"Failed to initialize FMOD recorder: %s", FMOD_ErrorString(result)); \
    self = nil; \
    return self; \
  } \
} while(0)

static const unsigned int kRecordingDuration = 60 * 60 * 2;

@implementation PHFMODRecorder {
  FMOD::System* _system;
  FMOD::Sound* _sound;
  FMOD::Channel* _channel;
  NSArray* _playbackDriverNames;
  NSArray* _recordDriverNames;
  int _recordDriverIndex;
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

    NSMutableArray *driverNames = [NSMutableArray array];
    for (int ix = 0; ix < numberOfDrivers; ++ix) {
      char name[256];

      result = _system->getDriverInfo(ix, name, 256, 0);
      INITCHECKFMODRESULT(result);
      [driverNames addObject:[NSString stringWithCString:name encoding:NSASCIIStringEncoding]];
    }
    _playbackDriverNames = [driverNames copy];

    result = _system->setDriver(0);
    INITCHECKFMODRESULT(result);


    // Recording drivers.

    numberOfDrivers = 0;
    result = _system->getRecordNumDrivers(&numberOfDrivers);
    INITCHECKFMODRESULT(result);

    driverNames = [NSMutableArray array];
    for (int ix = 0; ix < numberOfDrivers; ++ix) {
      char name[256];

      result = _system->getRecordDriverInfo(ix, name, 256, 0);
      INITCHECKFMODRESULT(result);
      [driverNames addObject:[NSString stringWithCString:name encoding:NSASCIIStringEncoding]];
    }
    _recordDriverNames = [driverNames copy];
    if (_recordDriverNames.count > 0) {
      _recordDriverIndex = 0;
    } else {
      _recordDriverIndex = -1;
    }

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

@end
