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

@implementation PHInfoPanel

- (void)awakeFromNib {
  [super awakeFromNib];

  [self.audioRecordingButton addItemsWithTitles:PHApp().audioRecorder.recordDriverNames];
  [self.audioOutputButton addItemsWithTitles:PHApp().audioRecorder.playbackDriverNames];

  [self updateListeningState];
}

- (void)updateListeningState {
  [self.audioRecordingButton selectItemAtIndex:PHApp().audioRecorder.recordDriverIndex];
  [self.audioOutputButton selectItemAtIndex:PHApp().audioRecorder.playbackDriverIndex];
  self.listeningButton.title = PHApp().audioRecorder.isListening ? @"Stop Listening" : @"Start Listening";
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

@end
