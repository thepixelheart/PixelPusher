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

#import <Accelerate/Accelerate.h>

static NSString* const PHInfoPanelVolumeLevelKey = @"PHInfoPanelVolumeLevelKey";
static NSString* const kPlaybackDriverNameUserDefaultsKey = @"kPlaybackDriverNameUserDefaultsKey";
static NSString* const kRecordingDriverNameUserDefaultsKey = @"kRecordingDriverNameUserDefaultsKey";

@interface PHChannelFft : NSObject
@end

@implementation PHChannelFft {
  COMPLEX_SPLIT _A;
  FFTSetup      _FFTSetup;
  BOOL          _isFFTSetup;
  vDSP_Length   _log2n;
  int _nOver2;

  float *_window;
  float *_amplitudes;
  float *_waveform;
}

- (void)dealloc {
  if (_FFTSetup) {
    vDSP_destroy_fftsetup(_FFTSetup);
  }
  if (_A.realp) {
    free(_A.realp);
  }
  if (_A.imagp) {
    free(_A.imagp);
  }
  if (_amplitudes) {
    free(_amplitudes);
  }
  if (_window) {
    free(_window);
  }
  if (_waveform) {
    free(_waveform);
  }
}

- (float *)amplitudes {
  return _amplitudes;
}

- (float *)waveform {
  return _waveform;
}

- (int)numberOfValues {
  return _nOver2;
}

- (int)numberOfWaveFormValues {
  return _nOver2 * 2;
}

/**
 Adapted from http://batmobile.blogs.ilrt.org/fourier-transforms-on-an-iphone/
 */
-(void)createFFTWithBufferSize:(float)bufferSize withAudioData:(float*)data {
  // Setup the length
  _log2n = log2f(bufferSize);

  // Calculate the weights array. This is a one-off operation.
  _FFTSetup = vDSP_create_fftsetup(_log2n, FFT_RADIX2);

  // For an FFT, numSamples must be a power of 2, i.e. is always even
  _nOver2 = bufferSize/2;

  // Populate *window with the values for a hamming window function
  _window = (float *)malloc(sizeof(float)*bufferSize);
  vDSP_hamm_window(_window, bufferSize, 0);

  // Define complex buffer
  _A.realp = (float *) malloc(_nOver2*sizeof(float));
  _A.imagp = (float *) malloc(_nOver2*sizeof(float));

  _amplitudes = (float *)malloc(sizeof(float)*_nOver2);
  _waveform = (float *)malloc(sizeof(float)*bufferSize);
}

- (void)updateFFTWithBufferSize:(float)bufferSize withAudioData:(float*)data {
  if (!_FFTSetup) {
    [self createFFTWithBufferSize:bufferSize withAudioData:data];
  }

  // Window the samples
  vDSP_vmul(data, 1, _window, 1, data, 1, bufferSize);

  // Pack samples:
  // C(re) -> A[n], C(im) -> A[n+1]
  vDSP_ctoz((COMPLEX*)data, 2, &_A, 1, _nOver2);

  // Perform a forward FFT using fftSetup and A
  // Results are returned in A
  vDSP_fft_zrip(_FFTSetup, &_A, 1, _log2n, FFT_FORWARD);

  for(int i=0; i<_nOver2; i++) {
    float mag = _A.realp[i]*_A.realp[i]+_A.imagp[i]*_A.imagp[i];
    _amplitudes[i] = mag;
  }

#if 0
  // Update the frequency domain plot
  [self.audioPlotFreq updateBuffer:amp
                    withBufferSize:nOver2];
#endif
}

@end

@implementation PHFMODRecorder {
  AudioDeviceList* _inputDeviceList;
  AudioDeviceList* _outputDeviceList;

  NSArray *_channels;

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
  if (_channels.count > 0) {
    *left = [_channels[0] amplitudes];
    *unified = [_channels[0] amplitudes];
  }
  if (_channels.count > 1) {
    *right = [_channels[1] amplitudes];
  }
}

- (NSInteger)numberOfSpectrumValues {
  return [[_channels firstObject] numberOfValues];
}

- (void)getWaveLeft:(float **)left right:(float **)right unified:(float **)unified difference:(float **)difference {
  if (_channels.count > 0) {
    *left = [_channels[0] waveform];
    *unified = [_channels[0] waveform];
  }
  if (_channels.count > 1) {
    *right = [_channels[1] waveform];
  }
}

- (NSInteger)numberOfWaveDataValues {
  return [[_channels firstObject] numberOfWaveFormValues];
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

  @synchronized(self) {
    if (_channels.count != numberOfChannels) {
      NSMutableArray* channels = [NSMutableArray array];
      for (NSInteger ix = 0; ix < numberOfChannels; ++ix) {
        [channels addObject:[PHChannelFft new]];
      }
      _channels = channels;
    }
  }

  for (NSInteger ix = 0; ix < numberOfChannels; ++ix) {
    PHChannelFft *channelFft = _channels[ix];
    @synchronized(channelFft) {
      [channelFft updateFFTWithBufferSize:bufferSize withAudioData:buffer[ix]];
      memcpy([channelFft waveform], buffer[ix], sizeof(float) * [channelFft numberOfWaveFormValues]);
    }
  }
}

@end
