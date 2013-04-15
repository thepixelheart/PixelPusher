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
#import "PHMIDIDriver.h"
#import "PHMIDIDevice.h"

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

const Byte PHLaunchpadColorToByte[PHLaunchpadColorCount] = {
  0x0C, // Off
  0x0D, // Red dim
  0x0F, // Red bright
  0x0B, // Red flashing
  0x1D, // Amber dim
  0x3F, // Amber bright
  0x3B, // Amber flashing
  0x3E, // Yellow bright
  0x3A, // Yellow flashing
  0x1C, // Green dim
  0x3C, // Green bright
  0x38, // Green flashing
};

#define PHBUTTONINDEXFROMGRIDXY(x, y) ((Byte)((((y) & 0x0F) << 4) + ((x) & 0x0F)))
#define PHARRAYINDEXFROMGRIDXY(x, y) ((y) * PHLaunchpadButtonGridWidth + (x))

static NSString* const kLaunchpadDeviceName = @"Launchpad";

@implementation PHLaunchpadDevice {
  PHMIDIDevice* _device;

  BOOL _bufferFlipper;
  NSTimeInterval _lastFlashTimestamp;
  BOOL _flashingOn;
  BOOL _flashingEnabled;
  BOOL _anyFlashers;

  PHLaunchpadColor _buttonColor[PHLaunchpadButtonGridWidth * PHLaunchpadButtonGridHeight];
  PHLaunchpadColor _topButtonColor[PHLaunchpadTopButtonCount];
  PHLaunchpadColor _sideButtonColor[PHLaunchpadSideButtonCount];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init {
  if ((self = [super init])) {
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(midiDevicesDidChangeNotification:)
               name:PHMIDIDriverDevicesDidChangeNotification object:nil];

    memset(_buttonColor, 0, sizeof(PHLaunchpadColor) * [self numberOfButtons]);
    memset(_topButtonColor, 0, sizeof(PHLaunchpadColor) * PHLaunchpadTopButtonCount);
    memset(_sideButtonColor, 0, sizeof(PHLaunchpadColor) * PHLaunchpadSideButtonCount);
  }
  return self;
}

#pragma mark - Buttons

- (NSInteger)numberOfButtons {
  return PHLaunchpadButtonGridWidth * PHLaunchpadButtonGridHeight;
}

#pragma mark - PHMIDIDriverDevicesDidChangeNotification

- (void)midiDevicesDidChangeNotification:(NSNotification *)notification {
  NSDictionary* devices = notification.userInfo[PHMIDIDevicesKey];

  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  if (nil != _device) {
    [nc removeObserver:self name:PHMIDIDeviceDidReceiveMessagesNotification object:_device];
  }

  _device = devices[kLaunchpadDeviceName];

  if (nil != _device) {
    [nc addObserver:self selector:@selector(didReceiveMIDIMessages:) name:PHMIDIDeviceDidReceiveMessagesNotification object:_device];

    [self syncDeviceState];
  }
}

#pragma mark - PHMIDIDeviceDidReceiveMessagesNotification

- (void)didReceiveMIDIMessages:(NSNotification *)notification {
  NSArray* messages = notification.userInfo[PHMIDIMessagesKey];
  NSLog(@"MEssages: %@", messages);
}

- (void)syncDeviceState {
  [self reset];
  [self enableFlashing];
  [self startDoubleBuffering];

  [self updateAllButtons];

  [self flipBuffer];
}

- (void)updateAllButtons {
  // Grid of buttons
  for (NSInteger index = 0; index < [self numberOfButtons]; ++index) {
    if (_buttonColor[index] != PHLaunchpadColorOff) {
      [self sendButtonColorMessage:_buttonColor[index] atX:index % 8 y:index / 8];
    }
  }

  // Top buttons
  for (NSInteger index = 0; index < PHLaunchpadTopButtonCount; ++index) {
    if (_topButtonColor[index] != PHLaunchpadColorOff) {
      [self sendTopButtonColorMessage:_topButtonColor[index] atIndex:index];
    }
  }

  // Side buttons
  for (NSInteger index = 0; index < PHLaunchpadSideButtonCount; ++index) {
    if (_sideButtonColor[index] != PHLaunchpadColorOff) {
      [self sendSideButtonColorMessage:_sideButtonColor[index] atIndex:index];
    }
  }
}

#pragma mark - Messages

- (void)sendButtonColorMessage:(PHLaunchpadColor)color atX:(NSInteger)x y:(NSInteger)y {
  if (_device) {
    PHMIDIMessage* msg = [[PHMIDIMessage alloc] initWithStatus:PHMIDIStatusNoteOn channel:0];
    msg.data1 = PHBUTTONINDEXFROMGRIDXY(x, y);
    msg.data2 = PHLaunchpadColorToByte[color];
    [_device sendMessage:msg];
  }
}

- (void)sendTopButtonColorMessage:(PHLaunchpadColor)color atIndex:(NSInteger)buttonIndex {
  if (_device) {
    PHMIDIMessage* msg = [[PHMIDIMessage alloc] initWithStatus:PHMIDIStatusControlChange channel:0];
    msg.data1 = (buttonIndex & 0x0F) + 0x68;
    msg.data2 = PHLaunchpadColorToByte[color];
    [_device sendMessage:msg];
  }
}

- (void)sendSideButtonColorMessage:(PHLaunchpadColor)color atIndex:(NSInteger)buttonIndex {
  if (_device) {
    PHMIDIMessage* msg = [[PHMIDIMessage alloc] initWithStatus:PHMIDIStatusNoteOn channel:0];
    msg.data1 = ((buttonIndex & 0x0F) << 4) | 0x08;
    msg.data2 = PHLaunchpadColorToByte[color];
    [_device sendMessage:msg];
  }
}

#pragma mark - Utilities

- (BOOL)isFlashingColor:(PHLaunchpadColor)color {
  return (color == PHLaunchpadColorAmberFlashing
          || color == PHLaunchpadColorGreenFlashing
          || color == PHLaunchpadColorRedFlashing
          || color == PHLaunchpadColorYellowFlashing);
}

#pragma mark - Public Methods

- (void)setButtonColor:(PHLaunchpadColor)color atX:(NSInteger)x y:(NSInteger)y {
  if ([self isFlashingColor:color]) {
    _anyFlashers = YES;
  }

  NSInteger index = PHARRAYINDEXFROMGRIDXY(x, y);
  if (_buttonColor[index] != color) {
    _buttonColor[index] = color;

    [self sendButtonColorMessage:color atX:x y:y];
  }
}

- (void)setButtonColor:(PHLaunchpadColor)color atButtonIndex:(NSInteger)buttonIndex {
  if ([self isFlashingColor:color]) {
    _anyFlashers = YES;
  }

  if (_buttonColor[buttonIndex] != color) {
    _buttonColor[buttonIndex] = color;

    [self sendButtonColorMessage:color atX:buttonIndex % 8 y:buttonIndex / 8];
  }
}

- (void)setTopButtonColor:(PHLaunchpadColor)color atIndex:(NSInteger)buttonIndex {
  if ([self isFlashingColor:color]) {
    _anyFlashers = YES;
  }

  if (_topButtonColor[buttonIndex] != color) {
    _topButtonColor[buttonIndex] = color;

    [self sendTopButtonColorMessage:color atIndex:buttonIndex];
  }
}

- (void)setSideButtonColor:(PHLaunchpadColor)color atIndex:(NSInteger)buttonIndex {
  if ([self isFlashingColor:color]) {
    _anyFlashers = YES;
  }

  if (_sideButtonColor[buttonIndex] != color) {
    _sideButtonColor[buttonIndex] = color;

    [self sendSideButtonColorMessage:color atIndex:buttonIndex];
  }
}

- (void)startDoubleBuffering {
  _bufferFlipper = YES;
  [self flipBuffer];
}

- (void)enableFlashing {
  _flashingEnabled = YES;

  if (_device) {
    PHMIDIMessage* message = [[PHMIDIMessage alloc] initWithStatus:PHMIDIStatusControlChange
                                                           channel:0];
    message.data1 = 0;
    message.data2 = 0x28;
    [_device sendMessage:message];
  }
}

- (void)flipBuffer {
  if (_device) {
    PHMIDIMessage* message = [[PHMIDIMessage alloc] initWithStatus:PHMIDIStatusControlChange
                                                           channel:0];
    message.data1 = 0;
    message.data2 = (_bufferFlipper ? 0x31 : 0x34) | (_flashingEnabled ? 0x08 : 0);
    _bufferFlipper = !_bufferFlipper;
    [_device sendMessage:message];
  }
}

- (void)reset {
  _anyFlashers = NO;

  if (_device) {
    PHMIDIMessage* message = [[PHMIDIMessage alloc] initWithStatus:PHMIDIStatusControlChange
                                                           channel:0];
    message.data1 = 0;
    message.data2 = 0;
    [_device sendMessage:message];
  }
}

- (void)tickFlashers {
  if (_anyFlashers && (0 == _lastFlashTimestamp || [NSDate timeIntervalSinceReferenceDate] - _lastFlashTimestamp > kFlashInterval)) {
    if (_device) {
      PHMIDIMessage* message = [[PHMIDIMessage alloc] initWithStatus:PHMIDIStatusControlChange
                                                             channel:0];
      message.data1 = 0;
      message.data2 = _flashingOn ? 0x20 : 0x21;
      _flashingOn = !_flashingOn;
      [_device sendMessage:message];
    }

    _lastFlashTimestamp = [NSDate timeIntervalSinceReferenceDate];
  }
}

@end
