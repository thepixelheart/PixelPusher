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

#import "PHInfoPanel.h"

#import "AppDelegate.h"
#import "PHFMODRecorder.h"

static NSString* const PHInfoPanelVolumeLevelKey = @"PHInfoPanelVolumeLevelKey";

@implementation PHInfoPanel

- (void)awakeFromNib {
  [super awakeFromNib];

  [self.audioRecordingButton addItemsWithTitles:PHApp().audioRecorder.recordDriverNames];
  [self.audioOutputButton addItemsWithTitles:PHApp().audioRecorder.playbackDriverNames];

  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  if ([defaults objectForKey:PHInfoPanelVolumeLevelKey]) {
    PHApp().audioRecorder.volume = [defaults floatForKey:PHInfoPanelVolumeLevelKey];
  }

  [self updateListeningState];
}

- (void)updateListeningState {
  [self.audioRecordingButton selectItemAtIndex:PHApp().audioRecorder.recordDriverIndex];
  [self.audioOutputButton selectItemAtIndex:PHApp().audioRecorder.playbackDriverIndex];
  self.listeningButton.title = PHApp().audioRecorder.isListening ? @"Stop Listening" : @"Start Listening";
  [self.volumeSlider setEnabled:PHApp().audioRecorder.isListening];
  [self.volumeSlider setDoubleValue:PHApp().audioRecorder.volume * self.volumeSlider.maxValue];
}

#pragma mark - Actions

- (IBAction)didTapListeningButton:(id)sender {
  [PHApp().audioRecorder toggleListening];

  [self updateListeningState];
}

- (IBAction)setAudioOutput:(NSPopUpButton *)sender {
  [PHApp().audioRecorder setPlaybackDriverIndex:(int)sender.indexOfSelectedItem];
  [self updateListeningState];
}

- (IBAction)setAudioInput:(NSPopUpButton *)sender {
  [PHApp().audioRecorder setRecordDriverIndex:(int)sender.indexOfSelectedItem];
  [self updateListeningState];
}

- (IBAction)setVolumeLevel:(NSSlider *)sender {
  PHApp().audioRecorder.volume = self.volumeSlider.doubleValue / self.volumeSlider.maxValue;

  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  [defaults setFloat:PHApp().audioRecorder.volume forKey:PHInfoPanelVolumeLevelKey];

  [self updateListeningState];
}

@end
