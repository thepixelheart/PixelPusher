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

#import "PHMIDIDriver.h"
#import "PHMIDIDevice.h"
#import "PHMIDIMessage+DJ2GO.h"

static NSString* const kDeviceName = @"Numark DJ2Go";

@implementation PHDJ2GODevice {
  PHMIDIDevice* _device;

  CGFloat _sliders[PHDJ2GOSliderCount];
  CGFloat _volumes[PHDJ2GOVolumeCount];
  BOOL _buttons[PHDJ2GOButtonCount];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init {
  if ((self = [super init])) {
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(midiDevicesDidChangeNotification:)
               name:PHMIDIDriverDevicesDidChangeNotification object:nil];

    memset(_sliders, 0, sizeof(CGFloat) * PHDJ2GOSliderCount);
    memset(_volumes, 0, sizeof(CGFloat) * PHDJ2GOVolumeCount);
    memset(_buttons, 0, sizeof(BOOL) * PHDJ2GOButtonCount);
  }
  return self;
}

#pragma mark - PHMIDIDriverDevicesDidChangeNotification

- (void)midiDevicesDidChangeNotification:(NSNotification *)notification {
  NSDictionary* devices = notification.userInfo[PHMIDIDevicesKey];

  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  if (nil != _device) {
    [nc removeObserver:self name:PHMIDIDeviceDidReceiveMessagesNotification object:_device];
  }

  _device = devices[kDeviceName];

  if (nil != _device) {
    [nc addObserver:self selector:@selector(didReceiveMIDIMessages:) name:PHMIDIDeviceDidReceiveMessagesNotification object:_device];
  }
}

#pragma mark - PHMIDIDeviceDidReceiveMessagesNotification

- (void)didReceiveMIDIMessages:(NSNotification *)notification {
  if ([NSThread currentThread] != [NSThread mainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self didReceiveMIDIMessages:notification];
    });
    return;
  }
  NSArray* messages = notification.userInfo[PHMIDIMessagesKey];
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

#pragma mark - Message Handling

- (void)slider:(PHDJ2GOSlider)slider didChange:(CGFloat)value {
  _sliders[slider] = value;

  [_delegate slider:slider didChangeValue:value];
}

- (void)volume:(PHDJ2GOVolume)volume didChange:(CGFloat)value {
  _volumes[volume] = value;

  [_delegate volume:volume didChangeValue:value];
}

- (void)knob:(PHDJ2GOKnob)knob didRotate:(PHDJ2GODirection)direction {
  [_delegate knob:knob didRotate:direction];
}

- (void)buttonWasPressed:(PHDJ2GOButton)button {
  _buttons[button] = YES;

  [_delegate buttonWasPressed:button];
}

- (void)buttonWasReleased:(PHDJ2GOButton)button {
  _buttons[button] = NO;

  [_delegate buttonWasReleased:button];
}

@end
