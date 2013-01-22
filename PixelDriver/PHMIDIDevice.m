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

#import "PHMIDIDevice.h"

#import "PHMIDIMessage.h"
#import <CoreMIDI/CoreMIDI.h>

static NSString* const kMIDISenderNameFormat = @"%@ to PixelPusher";
static NSString* const kMIDIDestinationNameFormat = @"PixelPusher to %@";

void PHMIDINotifyProc(const MIDINotification *msg, void *refCon);
void PHMIDIReadProc(const MIDIPacketList *pktList, void *readProcRefCon, void *srcConnRefCon);

@interface PHMIDISenderOperation : NSOperation
- (id)initWithList:(MIDIPacketList *)list outputPort:(MIDIPortRef)outputPortRef destination:(MIDIEndpointRef)launchpadDestinationRef message:(PHMIDIMessage *)message;
- (BOOL)appendedMessageIfInactive:(PHMIDIMessage *)message;
@end

@implementation PHMIDISenderOperation {
  MIDIPacketList* _packetList;
  MIDIPortRef _outputPortRef;
  MIDIEndpointRef _launchpadDestinationRef;
  NSMutableArray* _messages;
  BOOL _running;
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

- (BOOL)appendedMessageIfInactive:(PHMIDIMessage *)message {
  @synchronized(self) {
    if (self.isExecuting) {
      return NO;
    } else {
      [_messages addObject:message];
      return YES;
    }
  }
}

- (BOOL)isExecuting {
  @synchronized(self) {
    return [super isExecuting] || _running;
  }
}

- (void)main {
  @synchronized(self) {
    _running = YES;

    if (_launchpadDestinationRef) {
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

      err = MIDISend(_outputPortRef, _launchpadDestinationRef, _packetList);
      if (err != noErr)  {
        NSLog(@"Error sending packet: %ld", (long)err);
        return;
      }
    }

  // TODO: Notify people of messages being sent.
  }
}

@end

@interface PHMIDIDevice()
@property (nonatomic, assign, getter = isSysExDumping) BOOL sysExDumping;
@property (nonatomic, assign) NSInteger numberOfSysExReads;
@end

@implementation PHMIDIDevice {
  PHMIDIClient* _client;
  MIDIPortRef _inputPortRef;
  MIDIPortRef _outputPortRef;

  MIDIEndpointRef _sourceEndpointRef;
  MIDIEndpointRef _destinationRef;

  NSOperationQueue* _sendQueue;
  MIDIPacketList* _packetList;
}

- (void)dealloc {
  if (_sourceEndpointRef) {
    MIDIPortDisconnectSource(_inputPortRef, _sourceEndpointRef);
  }

  if (_packetList)  {
    free(_packetList);
  }
}

- (id)initWithClient:(PHMIDIClient *)client sourceEndpointRef:(MIDIEndpointRef)sourceEndpointRef {
  if ((self = [super init])) {
    _client = client;
    _sourceEndpointRef = sourceEndpointRef;

    _sendQueue = [[NSOperationQueue alloc] init];
    _sendQueue.maxConcurrentOperationCount = 1;

    CFStringRef destinationName = (__bridge CFStringRef)[NSString stringWithFormat:kMIDIDestinationNameFormat, [self name]];

    OSStatus status = MIDIInputPortCreate(client.clientRef, destinationName, PHMIDIReadProc, (__bridge void *)(self), &_inputPortRef);
    INITCHECKOSSTATUS(status);

    status = MIDIPortConnectSource(_inputPortRef, sourceEndpointRef, NULL);
    INITCHECKOSSTATUS(status);

    _packetList = (MIDIPacketList *)malloc(1024 * sizeof(char));
  }
  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:
          @"<%@ "
          @"name: %@, "
          @"manufacturer: %@, "
          @"model: %@, ",
          [super description],
          [self name],
          [self manufacturer],
          [self model]];
}

#pragma mark - Message Sending

- (void)sendMessage:(PHMIDIMessage *)message {
  if ([NSThread currentThread] != [NSThread mainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
     [self sendMessage:message];
    });
    return;
  }
  @synchronized(self) {
    for (PHMIDISenderOperation* op in _sendQueue.operations) {
      if ([op appendedMessageIfInactive:message]) {
        return;
      }
    }

    PHMIDISenderOperation* op = [[PHMIDISenderOperation alloc] initWithList:_packetList outputPort:_outputPortRef destination:_destinationRef message:message];
    [_sendQueue addOperation:op];
  }
}

- (void)receivedMessages:(NSArray *)messages {
  for (PHMIDIMessage* message in messages) {
    NSLog(@"Message: %@", message);
    // TODO: Implement receiving messages.
/*    if (message.status == PHMIDIStatusNoteOn || message.status == PHMIDIStatusControlChange) {
      BOOL pressed = (message.data2 == 0x7F);

      PHLaunchpadEvent event = message.launchpadEvent;
      int buttonIndex = message.launchpadButtonIndex;

      NSDictionary* userInfo =
      @{PHLaunchpadEventTypeUserInfoKey: [NSNumber numberWithInt:event],
        PHLaunchpadButtonPressedUserInfoKey: [NSNumber numberWithBool:pressed],
        PHLaunchpadButtonIndexInfoKey: [NSNumber numberWithInt:buttonIndex]};

      NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
      [nc postNotificationName:PHLaunchpadDidReceiveStateChangeNotification object:nil userInfo:userInfo];
    }*/
  }
}

#pragma mark - Public Methods

- (void)setDestinationEndpointRef:(MIDIEndpointRef)destinationEndpointRef {
  if (_destinationEndpointRef != destinationEndpointRef) {
    CFStringRef senderName = (__bridge CFStringRef)[NSString stringWithFormat:kMIDISenderNameFormat, [self name]];
    OSStatus status = MIDIOutputPortCreate(_client.clientRef, senderName, &_outputPortRef);
    if (status != noErr) {
      NSLog(@"Failed to bind output MIDI port");
    }
  }
}

- (NSString *)name {
  return [self.class nameFromEndpointRef:_sourceEndpointRef];
}

- (NSString *)manufacturer {
  return [self.class stringForKey:kMIDIPropertyManufacturer endpointRef:_sourceEndpointRef];
}

- (NSString *)model {
  return [self.class stringForKey:kMIDIPropertyModel endpointRef:_sourceEndpointRef];
}

+ (NSString *)stringForKey:(const CFStringRef)keyRef endpointRef:(MIDIEndpointRef)endpointRef {
  CFStringRef stringRef = nil;
  OSStatus status = MIDIObjectGetStringProperty(endpointRef, keyRef, &stringRef);
  if (status != noErr) {
    return nil;
  }
  return (__bridge NSString *)stringRef;
}

+ (NSString *)nameFromEndpointRef:(MIDIEndpointRef)endpointRef {
  return [self stringForKey:kMIDIPropertyName endpointRef:endpointRef];
}

@end

void PHMIDIReadProc(const MIDIPacketList *pktList, void *readProcRefCon, void *srcConnRefCon) {
  @autoreleasepool {
    PHMIDIDevice* device = (__bridge PHMIDIDevice *)(readProcRefCon);

    if (device.isSysExDumping) {
      ++device.numberOfSysExReads;
    }
    if (device.numberOfSysExReads > 128)  {
      device.numberOfSysExReads = 0;
      device.sysExDumping = NO;
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
                device.sysExDumping = YES;
              } else if (byte == PHMIDIStatusEndSysex) {
                device.sysExDumping = NO;
              }
              break;
          }

        } else if ((byte >= 0x00) && (byte <= 0x7F)
                   && !device.sysExDumping && latestMessage != nil)  {
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
      [device receivedMessages:messages];
    }
  }
}

