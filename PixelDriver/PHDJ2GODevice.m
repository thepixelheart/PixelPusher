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

#import "PHDJ2GODevice.h"

#import "PHMIDIHardware+Subclassing.h"
#import "PHMIDIDriver.h"
#import "PHMIDIDevice.h"
#import "PHMIDIMessage+DJ2GO.h"

static NSString* const kHardwareName = @"Numark DJ2Go";

@implementation PHDJ2GODevice {
  CGFloat _sliders[PHDJ2GOSliderCount];
  CGFloat _volumes[PHDJ2GOVolumeCount];
  BOOL _buttons[PHDJ2GOButtonCount];
  BOOL _buttonLEDs[PHDJ2GOButtonLEDCount];
}

- (id)init {
  if ((self = [super init])) {
    memset(_sliders, 0, sizeof(CGFloat) * PHDJ2GOSliderCount);
    memset(_volumes, 0, sizeof(CGFloat) * PHDJ2GOVolumeCount);
    memset(_buttons, 0, sizeof(BOOL) * PHDJ2GOButtonCount);
    memset(_buttonLEDs, 0, sizeof(BOOL) * PHDJ2GOButtonLEDCount);
  }
  return self;
}

+ (NSString *)hardwareName {
  return kHardwareName;
}

- (void)syncDeviceState {
  for (PHDJ2GOButton button = 0; button < PHDJ2GOButtonLEDCount; ++button) {
    [self sendButtonColorMessage:button ledStateEnabled:_buttonLEDs[button]];
  }
}

- (void)didReceiveMIDIMessages:(NSArray *)messages {
  for (PHMIDIMessage* message in messages) {
    PHDJ2GOMessageType type = message.dj2goType;
    switch (type) {
      case PHDJ2GOMessageTypeSlider:
        [self slider:message.dj2goSlider didChange:message.dj2goSliderValue];
        break;
      case PHDJ2GOMessageTypeVolume:
        [self volume:message.dj2goVolume didChange:message.dj2goVolumeValue];
        break;
      case PHDJ2GOMessageTypeKnob:
        [self knob:message.dj2goKnob didRotate:message.dj2goKnobDirection];
        break;
      case PHDJ2GOMessageTypeButtonDown:
        [self buttonWasPressed:message.dj2goButton];
        break;
      case PHDJ2GOMessageTypeButtonUp:
        [self buttonWasReleased:message.dj2goButton];
        break;

      default:
        NSLog(@"Unknown message type received %d", type);
        break;
    }
  }
}

- (void)sendButtonColorMessage:(PHDJ2GOButton)button ledStateEnabled:(BOOL)enabled {
  if (self.device) {
    PHMIDIMessage* msg = [[PHMIDIMessage alloc] initWithStatus:enabled ? PHMIDIStatusNoteOn : PHMIDIStatusNoteOff channel:0];
    msg.data1 = PHDJ2GOLEDButtonToByte[button];
    msg.data2 = 1;
    [self.device sendMessage:msg];
  }
}

#pragma mark - Message Handling

- (void)slider:(PHDJ2GOSlider)slider didChange:(CGFloat)value {
  _sliders[slider] = value;

  [_delegate dj2go:self slider:slider didChangeValue:value];
}

- (void)volume:(PHDJ2GOVolume)volume didChange:(CGFloat)value {
  _volumes[volume] = value;

  [_delegate dj2go:self volume:volume didChangeValue:value];
}

- (void)knob:(PHDJ2GOKnob)knob didRotate:(PHDJ2GODirection)direction {
  [_delegate dj2go:self knob:knob didRotate:direction];
}

- (void)buttonWasPressed:(PHDJ2GOButton)button {
  _buttons[button] = YES;

  [_delegate dj2go:self buttonWasPressed:button];
}

- (void)buttonWasReleased:(PHDJ2GOButton)button {
  _buttons[button] = NO;

  [_delegate dj2go:self buttonWasReleased:button];
}

- (void)setButton:(PHDJ2GOButton)button ledStateEnabled:(BOOL)enabled {
  if (button >= PHDJ2GOButtonLEDCount) {
    return;
  }

  if (_buttonLEDs[button] != enabled) {
    _buttonLEDs[button] = enabled;

    [self sendButtonColorMessage:button ledStateEnabled:enabled];
  }
}

@end
