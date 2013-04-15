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

#import <Foundation/Foundation.h>

// Notifications
extern NSString* const PHLaunchpadDidReceiveStateChangeNotification;
extern NSString* const PHLaunchpadDidConnectNotification;
extern NSString* const PHLaunchpadDidSendMIDIMessagesNotification;

// User info keys for PHLaunchpadDidReceiveStateChangeNotification
extern NSString* const PHLaunchpadEventTypeUserInfoKey; // PHLaunchpadEvent
// PHLaunchpadEvent*ButtonState
extern NSString* const PHLaunchpadButtonPressedUserInfoKey; // BOOL
extern NSString* const PHLaunchpadButtonIndexInfoKey; // NSInteger

// User info keys for NSString* const PHLaunchpadDidSendMIDIMessagesNotification
extern NSString* const PHLaunchpadMessagesUserInfoKey; // NSArray of PHMIDIMessage

typedef enum {
  PHLaunchpadTopButtonUpArrow,
  PHLaunchpadTopButtonDownArrow,
  PHLaunchpadTopButtonLeftArrow,
  PHLaunchpadTopButtonRightArrow,
  PHLaunchpadTopButtonSession,
  PHLaunchpadTopButtonUser1,
  PHLaunchpadTopButtonUser2,
  PHLaunchpadTopButtonMixer,
  PHLaunchpadTopButtonCount,
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
  PHLaunchpadSideButtonCount,
} PHLaunchpadSideButton;

typedef enum {
  PHLaunchpadEventGridButtonState,
  PHLaunchpadEventTopButtonState,
  PHLaunchpadEventRightButtonState,
} PHLaunchpadEvent;

typedef enum {
  PHLaunchpadColorOff,
  PHLaunchpadColorRedDim,
  PHLaunchpadColorRedBright,
  PHLaunchpadColorRedFlashing,
  PHLaunchpadColorAmberDim,
  PHLaunchpadColorAmberBright,
  PHLaunchpadColorAmberFlashing,
  PHLaunchpadColorYellowBright,
  PHLaunchpadColorYellowFlashing,
  PHLaunchpadColorGreenDim,
  PHLaunchpadColorGreenBright,
  PHLaunchpadColorGreenFlashing,

  PHLaunchpadColorCount,
} PHLaunchpadColor;

extern const NSInteger PHLaunchpadButtonGridWidth;
extern const NSInteger PHLaunchpadButtonGridHeight;

#define PHGRIDXFROMBUTTONINDEX(index) (NSInteger)((index) % PHLaunchpadButtonGridWidth)
#define PHGRIDYFROMBUTTONINDEX(index) (NSInteger)((index) / PHLaunchpadButtonGridWidth)

@interface PHLaunchpadDevice : NSObject

- (void)setButtonColor:(PHLaunchpadColor)color atX:(NSInteger)x y:(NSInteger)y;
- (void)setButtonColor:(PHLaunchpadColor)color atButtonIndex:(NSInteger)buttonIndex;
- (void)setTopButtonColor:(PHLaunchpadColor)color atIndex:(NSInteger)buttonIndex;
- (void)setSideButtonColor:(PHLaunchpadColor)color atIndex:(NSInteger)buttonIndex;

- (void)reset;
- (void)flipBuffer;

@end
