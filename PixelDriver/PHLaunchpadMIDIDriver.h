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

typedef enum {
  PHLaunchpadTopButtonUpArrow,
  PHLaunchpadTopButtonDownArrow,
  PHLaunchpadTopButtonLeftArrow,
  PHLaunchpadTopButtonRightArrow,
  PHLaunchpadTopButtonSession,
  PHLaunchpadTopButtonUser1,
  PHLaunchpadTopButtonUser2,
  PHLaunchpadTopButtonMixer,
} PHLaunchpadTopButton;

typedef enum {
  PHLaunchpadSideButtonVolume,
  PHLaunchpadSideButtonPan,
  PHLaunchpadSideButtonSendA,
  PHLaunchpadSideButtonSendB,
  PHLaunchpadSideButtonStop,
  PHLaunchpadSideButtonTrackOn,
  PHLaunchpadSideButtonSolo,
  PHLaunchpadSideButtonArm,
} PHLaunchpadSideButton;

typedef enum {
  PHLaunchpadEventGridButtonState,
  PHLaunchpadEventTopButtonState,
  PHLaunchpadEventRightButtonState,
} PHLaunchpadEvent;

// Notifications
extern NSString* const PHLaunchpadDidReceiveStateChangeNotification;

// User info keys for PHLaunchpadDidReceiveStateChangeNotification
extern NSString* const PHLaunchpadEventTypeUserInfoKey; // PHLaunchpadEvent
// PHLaunchpadEvent*ButtonState
extern NSString* const PHLaunchpadButtonPressedUserInfoKey; // BOOL
extern NSString* const PHLaunchpadButtonIndexInfoKey; // NSInteger

#define PHGRIDXFROMBUTTONINDEX(index) (NSInteger)((index) % 16)
#define PHGRIDYFROMBUTTONINDEX(index) (NSInteger)((index) / 16)

@interface PHLaunchpadMIDIDriver : NSObject
@end
