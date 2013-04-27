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

#import "PHMIDIMessage+LPD8.h"

@implementation PHMIDIMessage (LPD8)

- (PHLPD8MessageType)lpd8Type {
  PHLPD8MessageType type = PHLPD8MessageTypeUnknown;

  if (self.status == PHMIDIStatusNoteOn) {
    type = PHLPD8MessageTypeVelocityButtonDown;

  } else if (self.status == PHMIDIStatusNoteOff) {
    type = PHLPD8MessageTypeVelocityButtonUp;

  } else if (self.status == PHMIDIStatusControlChange) {
    type = PHLPD8MessageTypeVolume;
  }
  return type;
}

- (NSInteger)lpd8VelocityButtonIndex {
  switch (self.data1) {
    case 0x28:
      return 0;
    case 0x29:
      return 1;
    case 0x2A:
      return 2;
    case 0x2B:
      return 3;
    case 0x24:
      return 4;
    case 0x25:
      return 5;
    case 0x26:
      return 6;
    case 0x27:
      return 7;
  }
  return -1;
}

- (CGFloat)lpd8VelocityButtonIntensity {
  return (CGFloat)self.data2 / 0x7F;
}

- (NSInteger)lpd8VolumeIndex {
  return self.data1 - 1;
}

- (CGFloat)lpd8VolumeValue {
  return (CGFloat)self.data2 / 0x7F;
}

@end
