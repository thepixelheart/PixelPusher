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

#import "PHLaunchpadMIDIDriver.h"

#import "PHDisplayLink.h"
#import <CoreMIDI/CoreMIDI.h>

NSString* const PHLaunchpadDidReceiveStateChangeNotification = @"PHLaunchpadDidReceiveStateChangeNotification";
NSString* const PHLaunchpadDidConnectNotification = @"PHLaunchpadDidConnectNotification";
NSString* const PHLaunchpadEventTypeUserInfoKey = @"PHLaunchpadEventTypeUserInfoKey";
NSString* const PHLaunchpadButtonPressedUserInfoKey = @"PHLaunchpadButtonPressedUserInfoKey";
NSString* const PHLaunchpadButtonIndexInfoKey = @"PHLaunchpadButtonIndexInfoKey";

const NSInteger PHLaunchpadButtonGridWidth = 8;
const NSInteger PHLaunchpadButtonGridHeight = 8;
static const NSTimeInterval kFlashInterval = 0.5;

#define PHBUTTONINDEXFROMGRIDXY(x, y) ((Byte)((((y) & 0x0F) << 4) + ((x) & 0x0F)))

// http://www.midi.org/techspecs/midimessages.php
typedef enum {
  // Channel voice messages
  PHMIDIStatusNoteOff = 0x80,
  PHMIDIStatusNoteOn = 0x90,
  PHMIDIStatusAfterTouch = 0xA0,
  PHMIDIStatusControlChange = 0xB0,
  PHMIDIStatusProgramChange = 0xC0,
  PHMIDIStatusChannelPressure = 0xD0,
  PHMIDIStatusPitchWheel = 0xE0,

  // Channel mode messages
  PHMIDIStatusBeginSysex = 0xF0,
  PHMIDIStatusEndSysex = 0xF7,
} PHMIDIStatus;

static const Byte PHLaunchpadColorToByte[PHLaunchpadColorCount] = {
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

#define INITCHECKOSSTATUS(result) do {\
  if (result != noErr) { \
    NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:(result) userInfo:nil]; \
    NSLog(@"Failed to set up the MIDI client: %@", error); \
    self = nil; \
    return self; \
  } \
} while(0)

static NSString* const kLaunchpadDeviceName = @"Launchpad";

@interface PHMIDIMessage : NSObject

- (id)initWithStatus:(Byte)type channel:(Byte)channel;

@property (nonatomic, readonly) Byte status;
@property (nonatomic, readonly) Byte channel;
@property (nonatomic, assign) Byte data1;
@property (nonatomic, assign) Byte data2;

@end

@implementation PHMIDIMessage

- (id)initWithStatus:(Byte)status channel:(Byte)channel {
  if ((self = [super init])) {
    _status = status;
    _channel = channel;
    _data1 = -1;
    _data2 = -1;
  }
  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:
          @"<%@: 0x%X : %d : 0x%X : 0x%X>",
          [super description],
          _status,
          _channel,
          _data1,
          _data2];
}

@end

@interface PHMIDISenderOperation : NSOperation
- (id)initWithList:(MIDIPacketList *)list outputPort:(MIDIPortRef)outputPortRef destination:(MIDIEndpointRef)launchpadDestinationRef message:(PHMIDIMessage *)message;
- (void)appendMessage:(PHMIDIMessage *)message;
@end

@implementation PHMIDISenderOperation {
  MIDIPacketList* _packetList;
  MIDIPortRef _outputPortRef;
  MIDIEndpointRef _launchpadDestinationRef;
  NSMutableArray* _messages;
}

- (id)initWithList:(MIDIPacketList *)list outputPort:(MIDIPortRef)outputPortRef destination:(MIDIEndpointRef)launchpadDestinationRef message:(PHMIDIMessage *)message {
  if ((self = [super init])) {
    _packetList = list;
    _outputPortRef = outputPortRef;
    _launchpadDestinationRef = launchpadDestinationRef;
    _messages = [NSMutableArray arrayWithObject:message];
  }
  return self;
}

- (void)appendMessage:(PHMIDIMessage *)message {
  [_messages addObject:message];
}

- (void)main {
  MIDIPacket* newPacket = nil;
  OSStatus err = noErr;
  Byte scratchStruct[4];
  memset(scratchStruct, 0, sizeof(Byte) * 4);

  MIDIPacket* currentPacket = MIDIPacketListInit(_packetList);

  for (PHMIDIMessage* message in _messages) {
    scratchStruct[0] = message.status | message.channel;
    switch (message.status)  {
      case PHMIDIStatusNoteOff:
      case PHMIDIStatusNoteOn:
      case PHMIDIStatusControlChange:
        scratchStruct[1] = message.data1;
        scratchStruct[2] = message.data2;
        newPacket = MIDIPacketListAdd(_packetList, 1024, currentPacket, 0, 3, scratchStruct);
        break;
    }
    if (newPacket == NULL)  {
      NSLog(@"\t\terror adding new packet %s",__func__);
      return;
    }

    currentPacket = newPacket;
  }

  NSLog(@"Sent messages %@", _messages);

  err = MIDISend(_outputPortRef, _launchpadDestinationRef, _packetList);
  if (err != noErr)  {
    NSLog(@"Error sending packet: %ld", (long)err);
    return;
  }
}

@end

static NSString* const kMIDIClientName = @"PixelDriver MIDI Client";
static NSString* const kMIDIDestinationName = @"MIDI to PixelDriver";
static NSString* const kMIDISenderName = @"PixelDriver to MIDI";

void PHMIDINotifyProc(const MIDINotification *msg, void *refCon);
void PHMIDIReadProc(const MIDIPacketList *pktList, void *readProcRefCon, void *srcConnRefCon);

@interface PHLaunchpadMIDIDriver()
// MIDI state
@property (nonatomic, assign, getter = isSysExDumping) BOOL sysExDumping;
@property (nonatomic, assign) NSInteger numberOfSysExReads;
@end

@implementation PHLaunchpadMIDIDriver {
  MIDIClientRef _clientRef;
  MIDIEndpointRef _endpointRef;
  MIDIPortRef _inputPortRef;
  MIDIPortRef _outputPortRef;

  // Launchpad
  MIDIEndpointRef _launchpadSourceRef;
  MIDIEndpointRef _launchpadDestinationRef;

  MIDIPacketList* _packetList;

  NSOperationQueue* _sendQueue;
  BOOL _bufferFlipper;
  NSTimeInterval _lastFlashTimestamp;
  BOOL _flashingOn;
  BOOL _anyFlashers;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  if (_clientRef) {
    MIDIClientDispose(_clientRef);
  }

  if (_packetList)  {
    free(_packetList);
  }
}

- (id)init {
  if ((self = [super init])) {
    _sendQueue = [[NSOperationQueue alloc] init];
    _sendQueue.maxConcurrentOperationCount = 1;

    OSStatus status = MIDIClientCreate((__bridge CFStringRef)kMIDIClientName, PHMIDINotifyProc, (__bridge void *)(self), &_clientRef);
    INITCHECKOSSTATUS(status);

    CFStringRef destinationName = (__bridge CFStringRef)kMIDIDestinationName;
    CFStringRef senderName = (__bridge CFStringRef)kMIDISenderName;

    status = MIDIDestinationCreate(_clientRef, destinationName, PHMIDIReadProc, (__bridge void *)(self)
                                   , &_endpointRef);
    INITCHECKOSSTATUS(status);

    status = MIDIInputPortCreate(_clientRef, destinationName, PHMIDIReadProc, (__bridge void *)(self), &_inputPortRef);
    INITCHECKOSSTATUS(status);

    status = MIDIOutputPortCreate(_clientRef, senderName, &_outputPortRef);
    INITCHECKOSSTATUS(status);

    _packetList = (MIDIPacketList *)malloc(1024 * sizeof(char));

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(displayLinkDidFire:) name:PHDisplayLinkFiredNotification object:nil];
  }
  return self;
}

- (void)displayLinkDidFire:(NSNotification *)notification {
  [self tickFlashers];
}

- (void)setupDidChange {
  if (_launchpadSourceRef) {
    MIDIPortDisconnectSource(_inputPortRef, _launchpadSourceRef);
    _launchpadSourceRef = 0;
  }
  _launchpadDestinationRef = 0;

  ItemCount numberOfSources = MIDIGetNumberOfSources();
  for (ItemCount ix = 0; ix < numberOfSources; ++ix)  {
    MIDIEndpointRef endpoint = MIDIGetSource(ix);
    CFStringRef endpointNameRef = nil;
    OSStatus status = MIDIObjectGetStringProperty(endpoint, kMIDIPropertyName, &endpointNameRef);
    if (status != noErr) {
      continue;
    }
    NSString* endpointName = (__bridge NSString *)endpointNameRef;
    if ([endpointName isEqualToString:kLaunchpadDeviceName]) {
      _launchpadSourceRef = endpoint;
    }
    CFRelease(endpointNameRef);
  }

  ItemCount numberOfDestinations = MIDIGetNumberOfDestinations();
  for (ItemCount ix = 0; ix < numberOfDestinations; ++ix)  {
    MIDIEndpointRef endpoint = MIDIGetDestination(ix);

    CFStringRef endpointNameRef = nil;
    OSStatus status = MIDIObjectGetStringProperty(endpoint, kMIDIPropertyName, &endpointNameRef);
    if (status != noErr) {
      continue;
    }
    NSString* endpointName = (__bridge NSString *)endpointNameRef;
    if ([endpointName isEqualToString:kLaunchpadDeviceName]) {
      _launchpadDestinationRef = endpoint;
    }
    CFRelease(endpointNameRef);
  }

  if (_launchpadSourceRef) {
    OSStatus status = MIDIPortConnectSource(_inputPortRef, _launchpadSourceRef, NULL);
    if (status != noErr) {
      NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
      NSLog(@"Failed to create the MIDI source: %@", error);
      _launchpadSourceRef = 0;
      return;
    }

    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:PHLaunchpadDidConnectNotification object:nil];
  }
}

- (void)sendMessage:(PHMIDIMessage *)message {
  @synchronized(self) {
    for (PHMIDISenderOperation* op in _sendQueue.operations) {
      if (!op.isExecuting) {
        [op appendMessage:message];
        return;
      }
    }

    if (_launchpadDestinationRef) {
      PHMIDISenderOperation* op = [[PHMIDISenderOperation alloc] initWithList:_packetList outputPort:_outputPortRef destination:_launchpadDestinationRef message:message];
      [_sendQueue addOperation:op];
    }
  }
}

- (void)receivedMessages:(NSArray *)messages {
  for (PHMIDIMessage* message in messages) {
    if (message.status == PHMIDIStatusNoteOn || message.status == PHMIDIStatusControlChange) {
      BOOL pressed = (message.data2 == 0x7F);

      Byte keyValue = message.data1;
      PHLaunchpadEvent event;
      int buttonIndex;
      if (keyValue & 0x08) {
        if (message.status == PHMIDIStatusControlChange) {
          event = PHLaunchpadEventTopButtonState;
          buttonIndex = keyValue - 0x68;

        } else {
          event = PHLaunchpadEventRightButtonState;
          buttonIndex = ((keyValue & 0xF0) >> 4) & 0x0F;
        }
      } else {
        event = PHLaunchpadEventGridButtonState;
        int x = keyValue & 0x0F;
        int y = ((keyValue & 0xF0) >> 4) & 0x0F;
        buttonIndex = x + y * 8;
      }
      NSDictionary* userInfo =
      @{PHLaunchpadEventTypeUserInfoKey: [NSNumber numberWithInt:event],
        PHLaunchpadButtonPressedUserInfoKey: [NSNumber numberWithBool:pressed],
        PHLaunchpadButtonIndexInfoKey: [NSNumber numberWithInt:buttonIndex]};

      NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
      [nc postNotificationName:PHLaunchpadDidReceiveStateChangeNotification object:nil userInfo:userInfo];
    }
  }
}

#pragma mark - Public Methods

- (BOOL)isFlashingColor:(PHLaunchpadColor)color {
  return (color == PHLaunchpadColorAmberFlashing
          || color == PHLaunchpadColorGreenFlashing
          || color == PHLaunchpadColorRedFlashing
          || color == PHLaunchpadColorYellowFlashing);
}

- (void)setButtonColor:(PHLaunchpadColor)color atX:(NSInteger)x y:(NSInteger)y {
  [self setButtonColor:color atButtonIndex:PHBUTTONINDEXFROMGRIDXY(x, y)];
}

- (void)setButtonColor:(PHLaunchpadColor)color atButtonIndex:(NSInteger)buttonIndex {
  if ([self isFlashingColor:color]) {
    _anyFlashers = YES;
  }
  PHMIDIMessage* lightMessage = [[PHMIDIMessage alloc] initWithStatus:PHMIDIStatusNoteOn
                                                              channel:0];
  lightMessage.data1 = buttonIndex;
  lightMessage.data2 = PHLaunchpadColorToByte[color];
  dispatch_async(dispatch_get_main_queue(), ^{
    [self sendMessage:lightMessage];
  });
}

- (void)setTopButtonColor:(PHLaunchpadColor)color atIndex:(NSInteger)buttonIndex {
  if ([self isFlashingColor:color]) {
    _anyFlashers = YES;
  }
  PHMIDIMessage* lightMessage = [[PHMIDIMessage alloc] initWithStatus:PHMIDIStatusControlChange
                                                              channel:0];
  lightMessage.data1 = (buttonIndex & 0x0F) + 0x68;
  lightMessage.data2 = PHLaunchpadColorToByte[color];
  dispatch_async(dispatch_get_main_queue(), ^{
    [self sendMessage:lightMessage];
  });
}

- (void)setRightButtonColor:(PHLaunchpadColor)color atIndex:(NSInteger)buttonIndex {
  if ([self isFlashingColor:color]) {
    _anyFlashers = YES;
  }
  PHMIDIMessage* lightMessage = [[PHMIDIMessage alloc] initWithStatus:PHMIDIStatusNoteOn
                                                              channel:0];
  lightMessage.data1 = ((buttonIndex & 0x0F) << 4) | 0x08;
  lightMessage.data2 = PHLaunchpadColorToByte[color];
  dispatch_async(dispatch_get_main_queue(), ^{
    [self sendMessage:lightMessage];
  });
}

- (void)startDoubleBuffering {
  _bufferFlipper = YES;
  PHMIDIMessage* message = [[PHMIDIMessage alloc] initWithStatus:PHMIDIStatusControlChange
                                                         channel:0];
  message.data1 = 0;
  message.data2 = 0x31;
  dispatch_async(dispatch_get_main_queue(), ^{
    [self sendMessage:message];
  });
}

- (void)flipBuffer {
  PHMIDIMessage* message = [[PHMIDIMessage alloc] initWithStatus:PHMIDIStatusControlChange
                                                         channel:0];
  message.data1 = 0;
  message.data2 = _bufferFlipper ? 0x34 : 0x31;
  _bufferFlipper = !_bufferFlipper;
  dispatch_async(dispatch_get_main_queue(), ^{
    [self sendMessage:message];
  });
}

- (void)reset {
  _anyFlashers = NO;
  PHMIDIMessage* message = [[PHMIDIMessage alloc] initWithStatus:PHMIDIStatusControlChange
                                                         channel:0];
  message.data1 = 0;
  message.data2 = 0;
  dispatch_async(dispatch_get_main_queue(), ^{
    [self sendMessage:message];
  });
}

- (void)tickFlashers {
  if (_anyFlashers && (0 == _lastFlashTimestamp || [NSDate timeIntervalSinceReferenceDate] - _lastFlashTimestamp > kFlashInterval)) {
    PHMIDIMessage* message = [[PHMIDIMessage alloc] initWithStatus:PHMIDIStatusControlChange
                                                           channel:0];
    message.data1 = 0;
    message.data2 = _flashingOn ? 0x20 : 0x21;
    _flashingOn = !_flashingOn;
    dispatch_async(dispatch_get_main_queue(), ^{
      [self sendMessage:message];
    });

    _lastFlashTimestamp = [NSDate timeIntervalSinceReferenceDate];
  }
}

@end

void PHMIDINotifyProc(const MIDINotification *msg, void *refCon) {
  @autoreleasepool {
    if (msg->messageID == kMIDIMsgSetupChanged) {
      [(__bridge PHLaunchpadMIDIDriver *)refCon setupDidChange];
    }
  }
}

void PHMIDIReadProc(const MIDIPacketList *pktList, void *readProcRefCon, void *srcConnRefCon) {
  @autoreleasepool {
    PHLaunchpadMIDIDriver* driver = (__bridge PHLaunchpadMIDIDriver *)(readProcRefCon);

    if (driver.isSysExDumping) {
      ++driver.numberOfSysExReads;
    }
    if (driver.numberOfSysExReads > 128)  {
      driver.numberOfSysExReads = 0;
      driver.sysExDumping = NO;
    }

    NSMutableArray* messages = [NSMutableArray array];
    PHMIDIMessage* latestMessage = nil;
    NSInteger nextDataByteIndex = 0;

    MIDIPacket* packet = (MIDIPacket *)&pktList->packet[0];
    for (NSInteger ix = 0; ix < pktList->numPackets; ++ix) {
      for (NSInteger byteIndex = 0; byteIndex < packet->length; ++byteIndex)  {
        Byte byte = packet->data[byteIndex];
        if ((byte & 0x80) && (byte <= 0xFF)) {
          Byte status = (byte & 0xF0);
          switch (status)  {
            case PHMIDIStatusNoteOff:
            case PHMIDIStatusNoteOn:
            case PHMIDIStatusAfterTouch:
            case PHMIDIStatusControlChange:
            case PHMIDIStatusProgramChange:
            case PHMIDIStatusChannelPressure:
            case PHMIDIStatusPitchWheel: {
              Byte messageChannel = (Byte)(byte & 0x0F);
              latestMessage = [[PHMIDIMessage alloc] initWithStatus:status channel:messageChannel];
              [messages addObject:latestMessage];
              nextDataByteIndex = 0;
              break;
            }
            default:
              latestMessage = nil;
              if (byte == PHMIDIStatusBeginSysex) {
                driver.sysExDumping = YES;
              } else if (byte == PHMIDIStatusEndSysex) {
                driver.sysExDumping = NO;
              }
              break;
          }

        } else if ((byte >= 0x00) && (byte <= 0x7F)
                   && !driver.sysExDumping && latestMessage != nil)  {
          if (nextDataByteIndex == 0) {
            latestMessage.data1 = byte;
            ++nextDataByteIndex;

          } else if (nextDataByteIndex == 1) {
            latestMessage.data2 = byte;
            ++nextDataByteIndex;

          } else {
            NSLog(@"Unknown byte %x", byte);
          }
        }
      }

      packet = MIDIPacketNext(packet);
    }

    if (messages.count > 0) {
      [driver receivedMessages:messages];
    }
  }
}

