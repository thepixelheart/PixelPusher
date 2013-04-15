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

#import "PHMIDIMessage+Launchpad.h"

@implementation PHMIDIMessage (Launchpad)

- (PHLaunchpadEvent)launchpadEvent {
  PHLaunchpadEvent event;

  Byte keyValue = self.data1;
  if (keyValue & 0x08) {
    if (self.status == PHMIDIStatusControlChange) {
      event = PHLaunchpadEventTopButtonState;

    } else {
      event = PHLaunchpadEventRightButtonState;
    }
  } else {
    event = PHLaunchpadEventGridButtonState;
  }

  return event;
}

- (int)launchpadButtonIndex {
  int buttonIndex;

  Byte keyValue = self.data1;
  if (keyValue & 0x08) {
    if (self.status == PHMIDIStatusControlChange) {
      buttonIndex = keyValue - 0x68;

    } else {
      buttonIndex = ((keyValue & 0xF0) >> 4) & 0x0F;
    }
  } else {
    int x = keyValue & 0x0F;
    int y = ((keyValue & 0xF0) >> 4) & 0x0F;
    buttonIndex = x + y * 8;
  }

  return buttonIndex;
}

- (BOOL)launchpadButtonIsPressed {
  return (self.data2 == 0x7F);
}

@end
