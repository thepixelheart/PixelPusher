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

#import "CAPlayThrough.h"
#import "CAPlayThroughObjc.h"
#import "AudioDeviceList.h"

static NSString* const PHInfoPanelVolumeLevelKey = @"PHInfoPanelVolumeLevelKey";
static NSString* const kPlaybackDriverNameUserDefaultsKey = @"kPlaybackDriverNameUserDefaultsKey";
static NSString* const kRecordingDriverNameUserDefaultsKey = @"kRecordingDriverNameUserDefaultsKey";

@implementation PHFMODRecorder {
  AudioDeviceList* _inputDeviceList;
  AudioDeviceList* _outputDeviceList;

  CAPlayThroughHost* _playThroughHost;
}

- (void)dealloc {
  delete _inputDeviceList;
  delete _outputDeviceList;

  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init {
  if ((self = [super init])) {
    _volume = 1;
    _playbackDriverIndex = -1;
    _recordDriverIndex = -1;

    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:PHInfoPanelVolumeLevelKey]) {
      _volume = [defaults floatForKey:PHInfoPanelVolumeLevelKey];
    }

    _inputDeviceList = new AudioDeviceList(true);
    _outputDeviceList = new AudioDeviceList(false);

    _playbackDriverNames = [self devicesNamesFromList:_outputDeviceList];
    _recordDriverNames = [self devicesNamesFromList:_inputDeviceList];

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

    // Output device
    NSString* playbackDriverName = [prefs valueForKey:kPlaybackDriverNameUserDefaultsKey];
    if (nil == playbackDriverName) {
      playbackDriverName = @"Built-in Output";
    }
    for (int ix = 0; ix < _playbackDriverNames.count; ++ix) {
      if ([_playbackDriverNames[ix] isEqualToString:playbackDriverName]) {
        _playbackDriverIndex = ix;
      }
    }

    if (_playbackDriverIndex < 0 && _playbackDriverNames.count > 0) {
      // Couldn't find the driver. Pick the first.
      _playbackDriverIndex = 0;
      [prefs setValue:_recordDriverNames[0] forKey:kPlaybackDriverNameUserDefaultsKey];
    }

    // Input device
    NSString* recordingDriverName = [prefs valueForKey:kRecordingDriverNameUserDefaultsKey];
    if (nil == recordingDriverName) {
      recordingDriverName = @"Soundflower (2ch)";
    }
    for (int ix = 0; ix < _recordDriverNames.count; ++ix) {
      if ([_recordDriverNames[ix] isEqualToString:recordingDriverName]) {
        _recordDriverIndex = ix;
      }
    }

    if (_recordDriverIndex < 0 && _recordDriverNames.count > 0) {
      // Couldn't find the driver. Pick the first.
      _recordDriverIndex = 0;
      [prefs setValue:_recordDriverNames[0] forKey:kRecordingDriverNameUserDefaultsKey];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioUpdateNotification:) name:kAudioBufferNotification object:nil];
  }
  return self;
}

- (AudioDeviceID)inputDevice {
  AudioDeviceList::DeviceList &thelist = _inputDeviceList->GetList();
  return thelist[_recordDriverIndex].mID;
}

- (AudioDeviceID)outputDevice {
  AudioDeviceList::DeviceList &thelist = _outputDeviceList->GetList();
  return thelist[_playbackDriverIndex].mID;
}

- (NSArray *)devicesNamesFromList:(AudioDeviceList *)deviceList {
  AudioDeviceList::DeviceList &thelist = deviceList->GetList();
  NSMutableArray *names = [NSMutableArray array];
  int index = 0;
  for (AudioDeviceList::DeviceList::iterator i = thelist.begin(); i != thelist.end(); ++i, ++index) {
    [names addObject:[NSString stringWithCString: (*i).mName encoding:NSASCIIStringEncoding]];
  }
  return names;
}

- (BOOL)isListening {
  return _playThroughHost && _playThroughHost->IsRunning();
}

- (void)toggleListening {
  if ([self isListening]) {
    [self stopListening];

  } else {
    [self startListening];
  }
}

- (void)startListening {
  if (!_playThroughHost) {
    _playThroughHost = new CAPlayThroughHost([self inputDevice], [self outputDevice]);

  } else {
    if (_playThroughHost->PlayThroughExists()) {
      _playThroughHost->DeletePlayThrough();
    }

    _playThroughHost->CreatePlayThrough([self inputDevice], [self outputDevice]);
  }

	_playThroughHost->Start();
}

- (void)stopListening {
  if (_playThroughHost && _playThroughHost->IsRunning()) {
    _playThroughHost->Stop();
  }
}

- (void)setPlaybackDriverIndex:(int)playbackDriverIndex {
  _playbackDriverIndex = playbackDriverIndex;

  NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
  [prefs setValue:[_playbackDriverNames objectAtIndex:_playbackDriverIndex]
           forKey:kPlaybackDriverNameUserDefaultsKey];
  [prefs synchronize];

  if ([self isListening]) {
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

  if ([self isListening]) {
    [self stopListening];
    [self toggleListening];
  }
}

- (void)getSpectrumLeft:(float **)left right:(float **)right unified:(float **)unified {

}

- (NSInteger)numberOfSpectrumValues {
  return 0;
}

- (void)getHighResSpectrumLeft:(float **)left right:(float **)right unified:(float **)unified {

}

- (NSInteger)numberOfHighResSpectrumValues {
  return 0;
}

- (void)getWaveLeft:(float **)left right:(float **)right unified:(float **)unified difference:(float **)difference {

}

- (NSInteger)numberOfWaveDataValues {
  return 0;
}

- (void)setVolume:(float)volume {
  _volume = volume;

  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  [defaults setFloat:volume forKey:PHInfoPanelVolumeLevelKey];
}

#pragma mark - Notifications

- (void)audioUpdateNotification:(NSNotification *)notification {
  float** buffer = (float **)[notification.userInfo[kAudioBufferKey] pointerValue];
  UInt32 bufferSize = [notification.userInfo[kAudioBufferSizeKey] intValue];
  UInt32 numberOfChannels = [notification.userInfo[kAudioNumberOfChannelsKey] intValue];

  NSLog(@"%d %d", bufferSize, numberOfChannels);
}

@end
