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

typedef enum {
  PHLPD8MessageTypeVolume,
  PHLPD8MessageTypeVelocityButtonDown,
  PHLPD8MessageTypeVelocityButtonUp,

  PHLPD8MessageTypeUnknown
} PHLPD8MessageType;

typedef enum {
  PHLPD8NumberOfVelocityButtons = 8,
  PHLPD8NumberOfVolumes = 8,
} PHLPD8InputCounts;

@interface PHMIDIMessage (LPD8)

- (PHLPD8MessageType)lpd8Type;

// Velocity buttons
- (NSInteger)lpd8VelocityButtonIndex;
- (CGFloat)lpd8VelocityButtonIntensity;

// Volume knobs
- (NSInteger)lpd8VolumeIndex;
- (CGFloat)lpd8VolumeValue;

@end
