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

#import "PHLPD8Device.h"

#import "PHMIDIHardware+Subclassing.h"
#import "PHMIDIMessage+LPD8.h"

static NSString* const kHardwareName = @"LPD8";

@implementation PHLPD8Device {
  CGFloat _buttonVelocities[PHLPD8NumberOfVelocityButtons];
  BOOL _buttons[PHLPD8NumberOfVelocityButtons];
  CGFloat _volumes[PHLPD8NumberOfVolumes];
}

- (id)init {
  if ((self = [super init])) {
    memset(_buttonVelocities, 0, sizeof(CGFloat) * PHLPD8NumberOfVelocityButtons);
    memset(_buttons, 0, sizeof(BOOL) * PHLPD8NumberOfVelocityButtons);
    memset(_volumes, 0, sizeof(CGFloat) * PHLPD8NumberOfVolumes);
  }
  return self;
}

+ (NSString *)hardwareName {
  return kHardwareName;
}

- (void)syncDeviceState {

}

- (void)didReceiveMIDIMessages:(NSArray *)messages {
  for (PHMIDIMessage* message in messages) {
    PHLPD8MessageType type = message.lpd8Type;
    switch (type) {
      case PHLPD8MessageTypeVolume:
        [self volume:message.lpd8VolumeIndex didChange:message.lpd8VolumeValue];
        break;
      case PHLPD8MessageTypeVelocityButtonDown:
        [self buttonWasPressed:message.lpd8VelocityButtonIndex
                  withVelocity:message.lpd8VelocityButtonIntensity];
        break;
      case PHLPD8MessageTypeVelocityButtonUp:
        [self buttonWasReleased:message.lpd8VelocityButtonIndex];
        break;

      default:
        NSLog(@"Unknown message type received %d", type);
        break;
    }
  }
}

#pragma mark - Message Handling

- (void)volume:(NSInteger)volume didChange:(CGFloat)value {
  _volumes[volume] = value;

  [_delegate volume:volume didChangeValue:value];
}

- (void)buttonWasPressed:(NSInteger)button withVelocity:(CGFloat)velocity {
  _buttonVelocities[button] = velocity;
  _buttons[button] = YES;

  [_delegate buttonWasPressed:button withVelocity:velocity];
}

- (void)buttonWasReleased:(NSInteger)button {
  _buttonVelocities[button] = 0;
  _buttons[button] = NO;

  [_delegate buttonWasReleased:button];
}

@end
