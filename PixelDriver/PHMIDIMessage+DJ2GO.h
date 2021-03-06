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

#import "PHMIDIMessage.h"

#import "PHDJ2GODevice.h"

extern const Byte PHDJ2GOLEDButtonToByte[PHDJ2GOButtonLEDCount];

typedef enum {
  PHDJ2GOMessageTypeSlider,
  PHDJ2GOMessageTypeVolume,
  PHDJ2GOMessageTypeKnob,
  PHDJ2GOMessageTypeButtonDown,
  PHDJ2GOMessageTypeButtonUp,

  PHDJ2GOMessageTypeUnknown
} PHDJ2GOMessageType;

@interface PHMIDIMessage (DJ2GO)

- (PHDJ2GOMessageType)dj2goType;

// Sliders
- (PHDJ2GOSlider)dj2goSlider;
- (CGFloat)dj2goSliderValue;

// Volume knobs
- (PHDJ2GOVolume)dj2goVolume;
- (CGFloat)dj2goVolumeValue;

// Knobs
- (PHDJ2GOKnob)dj2goKnob;
- (PHDJ2GODirection)dj2goKnobDirection;

// Buttons
- (PHDJ2GOButton)dj2goButton;

@end
