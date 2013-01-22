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

#import "PHLaunchpadDevice.h"

#import "PHMIDIMessage+Launchpad.h"

NSString* const PHLaunchpadDidReceiveStateChangeNotification = @"PHLaunchpadDidReceiveStateChangeNotification";
NSString* const PHLaunchpadDidConnectNotification = @"PHLaunchpadDidConnectNotification";
NSString* const PHLaunchpadDidSendMIDIMessagesNotification = @"PHLaunchpadDidSendMIDIMessagesNotification";
NSString* const PHLaunchpadEventTypeUserInfoKey = @"PHLaunchpadEventTypeUserInfoKey";
NSString* const PHLaunchpadButtonPressedUserInfoKey = @"PHLaunchpadButtonPressedUserInfoKey";
NSString* const PHLaunchpadButtonIndexInfoKey = @"PHLaunchpadButtonIndexInfoKey";
NSString* const PHLaunchpadMessagesUserInfoKey = @"PHLaunchpadMessagesUserInfoKey";

const NSInteger PHLaunchpadButtonGridWidth = 8;
const NSInteger PHLaunchpadButtonGridHeight = 8;
static const NSTimeInterval kFlashInterval = 0.1;

#define PHBUTTONINDEXFROMGRIDXY(x, y) ((Byte)((((y) & 0x0F) << 4) + ((x) & 0x0F)))

static NSString* const kLaunchpadDeviceName = @"Launchpad";

@implementation PHLaunchpadDevice {
  BOOL _bufferFlipper;
  NSTimeInterval _lastFlashTimestamp;
  BOOL _flashingOn;
  BOOL _flashingEnabled;
  BOOL _anyFlashers;
}

- (BOOL)isFlashingColor:(PHLaunchpadColor)color {
  return (color == PHLaunchpadColorAmberFlashing
          || color == PHLaunchpadColorGreenFlashing
          || color == PHLaunchpadColorRedFlashing
          || color == PHLaunchpadColorYellowFlashing);
}

- (void)setButtonColor:(PHLaunchpadColor)color atX:(NSInteger)x y:(NSInteger)y {
  if ([self isFlashingColor:color]) {
    _anyFlashers = YES;
  }
  PHMIDIMessage* lightMessage = [[PHMIDIMessage alloc] initWithStatus:PHMIDIStatusNoteOn
                                                              channel:0];
  lightMessage.data1 = PHBUTTONINDEXFROMGRIDXY(x, y);
  lightMessage.data2 = PHLaunchpadColorToByte[color];
  //[self sendMessage:lightMessage];
}

- (void)setButtonColor:(PHLaunchpadColor)color atButtonIndex:(NSInteger)buttonIndex {
  if ([self isFlashingColor:color]) {
    _anyFlashers = YES;
  }
  PHMIDIMessage* lightMessage = [[PHMIDIMessage alloc] initWithStatus:PHMIDIStatusNoteOn
                                                              channel:0];
  lightMessage.data1 = PHBUTTONINDEXFROMGRIDXY(buttonIndex % 8, buttonIndex / 8);
  lightMessage.data2 = PHLaunchpadColorToByte[color];
  //[self sendMessage:lightMessage];
}

- (void)setTopButtonColor:(PHLaunchpadColor)color atIndex:(NSInteger)buttonIndex {
  if ([self isFlashingColor:color]) {
    _anyFlashers = YES;
  }
  PHMIDIMessage* lightMessage = [[PHMIDIMessage alloc] initWithStatus:PHMIDIStatusControlChange
                                                              channel:0];
  lightMessage.data1 = (buttonIndex & 0x0F) + 0x68;
  lightMessage.data2 = PHLaunchpadColorToByte[color];
  //[self sendMessage:lightMessage];
}

- (void)setRightButtonColor:(PHLaunchpadColor)color atIndex:(NSInteger)buttonIndex {
  if ([self isFlashingColor:color]) {
    _anyFlashers = YES;
  }
  PHMIDIMessage* lightMessage = [[PHMIDIMessage alloc] initWithStatus:PHMIDIStatusNoteOn
                                                              channel:0];
  lightMessage.data1 = ((buttonIndex & 0x0F) << 4) | 0x08;
  lightMessage.data2 = PHLaunchpadColorToByte[color];
  //[self sendMessage:lightMessage];
}

- (void)startDoubleBuffering {
  _bufferFlipper = YES;
  [self flipBuffer];
}

- (void)enableFlashing {
  _flashingEnabled = YES;
  PHMIDIMessage* message = [[PHMIDIMessage alloc] initWithStatus:PHMIDIStatusControlChange
                                                         channel:0];
  message.data1 = 0;
  message.data2 = 0x28;
  //[self sendMessage:message];
}

- (void)flipBuffer {
  PHMIDIMessage* message = [[PHMIDIMessage alloc] initWithStatus:PHMIDIStatusControlChange
                                                         channel:0];
  message.data1 = 0;
  message.data2 = (_bufferFlipper ? 0x31 : 0x34) | (_flashingEnabled ? 0x08 : 0);
  _bufferFlipper = !_bufferFlipper;
  //[self sendMessage:message];
}

- (void)reset {
  _anyFlashers = NO;
  PHMIDIMessage* message = [[PHMIDIMessage alloc] initWithStatus:PHMIDIStatusControlChange
                                                         channel:0];
  message.data1 = 0;
  message.data2 = 0;
  //[self sendMessage:message];
}

- (void)tickFlashers {
  if (_anyFlashers && (0 == _lastFlashTimestamp || [NSDate timeIntervalSinceReferenceDate] - _lastFlashTimestamp > kFlashInterval)) {
    PHMIDIMessage* message = [[PHMIDIMessage alloc] initWithStatus:PHMIDIStatusControlChange
                                                           channel:0];
    message.data1 = 0;
    message.data2 = _flashingOn ? 0x20 : 0x21;
    _flashingOn = !_flashingOn;
    //[self sendMessage:message];

    _lastFlashTimestamp = [NSDate timeIntervalSinceReferenceDate];
  }
}

@end
