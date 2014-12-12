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

#import "AudioDeviceList.h"

static NSString* const PHInfoPanelVolumeLevelKey = @"PHInfoPanelVolumeLevelKey";
static NSString* const kPlaybackDriverNameUserDefaultsKey = @"kPlaybackDriverNameUserDefaultsKey";
static NSString* const kRecordingDriverNameUserDefaultsKey = @"kRecordingDriverNameUserDefaultsKey";

@implementation PHFMODRecorder {
  BOOL _listening;

  AudioDeviceList *_inputDeviceList;
  AudioDeviceList	*_outputDeviceList;
}

- (void)dealloc {
  delete _inputDeviceList;
  delete _outputDeviceList;
}

- (id)init {
  if ((self = [super init])) {
    _volume = 1;

    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:PHInfoPanelVolumeLevelKey]) {
      _volume = [defaults floatForKey:PHInfoPanelVolumeLevelKey];
    }

    _inputDeviceList = new AudioDeviceList(true);
    _outputDeviceList = new AudioDeviceList(false);

    _playbackDriverNames = [self devicesNamesFromList:_outputDeviceList];
    _recordDriverNames = [self devicesNamesFromList:_inputDeviceList];
  }
  return self;
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
  return _listening;
}

- (void)toggleListening {
  _listening = !_listening;

  if (_listening) {

  } else {
    [self stopListening];
  }
}

- (void)startPlaying {
  if (_listening) {
  }
}

- (void)stopListening {
  _listening = NO;
}

- (void)setPlaybackDriverIndex:(int)playbackDriverIndex {
  _playbackDriverIndex = playbackDriverIndex;

  NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
  [prefs setValue:[_playbackDriverNames objectAtIndex:_playbackDriverIndex]
           forKey:kPlaybackDriverNameUserDefaultsKey];
  [prefs synchronize];

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

@end
