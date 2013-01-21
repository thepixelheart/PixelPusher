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

#import <Foundation/Foundation.h>
#import "PHLaunchpadMIDIDriver.h"

// http://www.midi.org/techspecs/midimessages.php
typedef enum {
  // Channel voice messages
  PHMIDIStatusNoteOff = 0x80,
  PHMIDIStatusNoteOn = 0x90,
  PHMIDIStatusAfterTouch = 0xA0,
  PHMIDIStatusControlChange = 0xB0,
  PHMIDIStatusProgramChange = 0xC0,
  PHMIDIStatusChannelPressure = 0xD0,
  PHMIDIStatusPitchWheel = 0xE0,

  // Channel mode messages
  PHMIDIStatusBeginSysex = 0xF0,
  PHMIDIStatusEndSysex = 0xF7,
} PHMIDIStatus;

@interface PHMIDIMessage : NSObject

- (id)initWithStatus:(Byte)type channel:(Byte)channel;

@property (nonatomic, readonly) Byte status;
@property (nonatomic, readonly) Byte channel;
@property (nonatomic, assign) Byte data1;
@property (nonatomic, assign) Byte data2;

@end
