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

#import "PHAudioPrefsPage.h"

#import "AppDelegate.h"
#import "PHSystemState.h"
#import "PHFMODRecorder.h"

typedef enum {
  PHAudioPrefIdSource,
  PHAudioPrefIdDestination,
  PHAudioPrefIdPlaybackEnabled,
  PHAudioPrefIdVolume,
  PHAudioPrefIdResetScales,
} PHAudioPrefId;

@implementation PHAudioPrefsPage

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    [self addRowWithLabel:@"Audio Source" popUpButtonId:PHAudioPrefIdSource selectedIndex:PHApp().audioRecorder.recordDriverIndex];
    [self addRowWithLabel:@"Audio Destination" popUpButtonId:PHAudioPrefIdDestination selectedIndex:PHApp().audioRecorder.playbackDriverIndex];
    [self addRowWithLabel:@"Playback" buttonId:PHAudioPrefIdPlaybackEnabled];
    [self addRowWithLabel:@"Volume" sliderId:PHAudioPrefIdVolume];
    [self addRowWithLabel:@"Reset Scales" buttonId:PHAudioPrefIdResetScales];
  }
  return self;
}

- (NSString *)titleForButtonId:(NSInteger)buttonId {
  if (buttonId == PHAudioPrefIdPlaybackEnabled) {
    return PHApp().audioRecorder.isListening ? @"Stop Listening" : @"Start Listening";
  } else if (buttonId == PHAudioPrefIdResetScales) {
    return @"Reset Scales";
  } else {
    return nil;
  }
}

- (NSArray *)popUpItemTitlesForId:(NSInteger)popUpButtonId {
  if (popUpButtonId == PHAudioPrefIdSource) {
    return PHApp().audioRecorder.recordDriverNames;

  } else if (popUpButtonId == PHAudioPrefIdDestination) {
    return PHApp().audioRecorder.playbackDriverNames;
  }
  return nil;
}

- (float)valueForSliderId:(NSInteger)sliderId {
  if (sliderId == PHAudioPrefIdVolume) {
    return [PHApp().audioRecorder volume];
  }
  return 0;
}

#pragma mark - Actions

- (void)didMoveSlider:(NSSlider *)slider {
  if (slider.tag == PHAudioPrefIdVolume) {
    [PHApp().audioRecorder setVolume:slider.floatValue];
  }
}

- (void)didTapButton:(NSButton *)button {
  if (button.tag == PHAudioPrefIdPlaybackEnabled) {
    [PHApp().audioRecorder toggleListening];
    [[self viewWithTag:button.tag] setTitle:[self titleForButtonId:button.tag]];

  } else if (button.tag == PHAudioPrefIdResetScales) {
    [[PHApp() animationDriver] resetScales];
  }
  [super didTapButton:button];
}

- (void)didChangePopUpButton:(NSPopUpButton *)button {
  if (button.tag == PHAudioPrefIdSource) {
    [PHApp().audioRecorder setRecordDriverIndex:(int)button.indexOfSelectedItem];
  } else if (button.tag == PHAudioPrefIdDestination) {
    [PHApp().audioRecorder setPlaybackDriverIndex:(int)button.indexOfSelectedItem];
  }
}

@end
