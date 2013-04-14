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

#import "PHMIDIMessage+DJ2GO.h"

#import "PHDJ2GODevice.h"

// Sliders
static const Byte kLeftSliderValue = 0xD;
static const Byte kRightSliderValue = 0xE;
static const Byte kMidSliderValue = 0xA;

// Volume
static const Byte kVolumeAValue = 0x8;
static const Byte kVolumeBValue = 0x9;
static const Byte kVolumeMasterValue = 0x17;
static const Byte kVolumeHeadphonesValue = 0xB;

// Knobs
static const Byte kBrowseKnobValue = 0x1A;
static const Byte kLeftKnobValue = 0x19;
static const Byte kRightKnobValue = 0x18;

// Buttons
static const Byte kLeftPitchBegNegValue = 0x44;
static const Byte kLeftPitchBegPosValue = 0x43;
static const Byte kLeftSyncValue = 0x40;
static const Byte kLeftHeadphonesValue = 0x65;
static const Byte kLeftCueValue = 0x33;
static const Byte kLeftPlayPauseValue = 0x3B;

static const Byte kRightPitchBegNegValue = 0x46;
static const Byte kRightPitchBegPosValue = 0x45;
static const Byte kRightSyncValue = 0x47;
static const Byte kRightHeadphonesValue = 0x66;
static const Byte kRightCueValue = 0x3C;
static const Byte kRightPlayPauseValue = 0x42;

static const Byte kLoadAValue = 0x4B;
static const Byte kLoadBValue = 0x34;
static const Byte kBackValue = 0x59;
static const Byte kEnterValue = 0x5A;

const Byte PHDJ2GOLEDButtonToByte[PHDJ2GOButtonLEDCount] = {
  kLeftSyncValue,
  kLeftHeadphonesValue,
  kLeftCueValue,
  kLeftPlayPauseValue,
  kRightSyncValue,
  kRightHeadphonesValue,
  kRightCueValue,
  kRightPlayPauseValue,
};

@implementation PHMIDIMessage (DJ2GO)

- (PHDJ2GOMessageType)dj2goType {
  PHDJ2GOMessageType type = PHDJ2GOMessageTypeUnknown;

  Byte component = self.data1;
  if (self.status == PHMIDIStatusControlChange) {

    switch (component ) {
      case kLeftSliderValue:
      case kRightSliderValue:
      case kMidSliderValue:
        return PHDJ2GOMessageTypeSlider;

      case kVolumeAValue:
      case kVolumeBValue:
      case kVolumeMasterValue:
      case kVolumeHeadphonesValue:
        return PHDJ2GOMessageTypeVolume;

      case kBrowseKnobValue:
      case kLeftKnobValue:
      case kRightKnobValue:
        return PHDJ2GOMessageTypeKnob;
    }

  } else if (self.status == PHMIDIStatusNoteOn) {
    type = PHDJ2GOMessageTypeButtonDown;

  } else if (self.status == PHMIDIStatusNoteOff) {
    type = PHDJ2GOMessageTypeButtonUp;
  }
  return type;
}

#pragma mark - Sliders

- (PHDJ2GOSlider)dj2goSlider {
  Byte component = self.data1;

  switch (component ) {
    case kLeftSliderValue: return PHDJ2GOSliderLeft;
    case kRightSliderValue: return PHDJ2GOSliderRight;
    case kMidSliderValue: return PHDJ2GOSliderMid;

    default: return PHDJ2GOSliderUnknown;
  }
}

- (CGFloat)dj2goSliderValue {
  Byte value = self.data2;
  return (CGFloat)value / (CGFloat)0x7F;
}

#pragma mark - Volume Knobs

- (PHDJ2GOVolume)dj2goVolume {
  Byte component = self.data1;

  switch (component ) {
    case kVolumeAValue: return PHDJ2GOVolumeA;
    case kVolumeBValue: return PHDJ2GOVolumeB;
    case kVolumeMasterValue: return PHDJ2GOVolumeMaster;
    case kVolumeHeadphonesValue: return PHDJ2GOVolumeHeadphones;

    default: return PHDJ2GOKnobUnknown;
  }
}

- (CGFloat)dj2goVolumeValue {
  Byte value = self.data2;
  return (CGFloat)value / (CGFloat)0x7F;
}

#pragma mark - Knobs

- (PHDJ2GOKnob)dj2goKnob {
  Byte component = self.data1;

  switch (component ) {
    case kBrowseKnobValue: return PHDJ2GOKnobBrowse;
    case kLeftKnobValue: return PHDJ2GOKnobLeft;
    case kRightKnobValue: return PHDJ2GOKnobRight;

    default: return PHDJ2GOKnobUnknown;
  }
}

- (PHDJ2GODirection)dj2goKnobDirection {
  Byte direction = self.data2;
  switch (direction) {
    case 0x01: return PHDJ2GODirectionCw;
    case 0x7F: return PHDJ2GODirectionCcw;

    default: return PHDJ2GODirectionUnknown;
  }
}

#pragma mark - Buttons

- (PHDJ2GOButton)dj2goButton {
  Byte component = self.data1;

  switch (component) {
    case kLeftPitchBegNegValue: return PHDJ2GOButtonLeftPitchBendNeg;
    case kLeftPitchBegPosValue: return PHDJ2GOButtonLeftPitchBendPos;
    case kLeftSyncValue: return PHDJ2GOButtonLeftSync;
    case kLeftHeadphonesValue: return PHDJ2GOButtonLeftHeadphones;
    case kLeftCueValue: return PHDJ2GOButtonLeftCue;
    case kLeftPlayPauseValue: return PHDJ2GOButtonLeftPlayPause;

    case kRightPitchBegNegValue: return PHDJ2GOButtonRightPitchBendNeg;
    case kRightPitchBegPosValue: return PHDJ2GOButtonRightPitchBendPos;
    case kRightSyncValue: return PHDJ2GOButtonRightSync;
    case kRightHeadphonesValue: return PHDJ2GOButtonRightHeadphones;
    case kRightCueValue: return PHDJ2GOButtonRightCue;
    case kRightPlayPauseValue: return PHDJ2GOButtonRightPlayPause;

    case kLoadAValue: return PHDJ2GOButtonLoadA;
    case kLoadBValue: return PHDJ2GOButtonLoadB;
    case kBackValue: return PHDJ2GOButtonBack;
    case kEnterValue: return PHDJ2GOButtonEnter;

    default: return PHDJ2GOButtonUnknown;
  }
}

@end
