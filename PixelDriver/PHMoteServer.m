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

#import "PHMoteServer.h"

#import "PHMote.h"
#import "PHMote+Private.h"
#import "PHMoteState+Private.h"

#include <CoreFoundation/CoreFoundation.h>
#include <sys/socket.h>
#include <netinet/in.h>

typedef enum {
  PHMoteMessageHello,
  PHMoteMessageButton,
  PHMoteMessageJoystickMoved,
  PHMoteMessageJoystickStopped,
  PHMoteMessageUnknown
} PHMoteMessage;

@interface PHMoteMessageState : NSObject
@end

@implementation PHMoteMessageState {
  PHMoteMessage _message;
  NSInteger _numberOfAdditionalBytes;
  NSInteger _numberOfReadBytes;
  uint8_t _additionalBytes[8];
  NSMutableString* _alias;
}

- (id)init {
  if ((self = [super init])) {
    _message = PHMoteMessageUnknown;
  }
  return self;
}

- (id)readByte:(uint8_t)byte {
  id result = nil;

  if (_message == PHMoteMessageUnknown) {
    _numberOfReadBytes = 0;

    if (byte == 'h') {
      _message = PHMoteMessageHello;
      _alias = [NSMutableString string];

    } else if (byte == 'b') {
      _message = PHMoteMessageButton;
      // 1 byte additional data: 'a' or 'b'

    } else if (byte == 'm') {
      _message = PHMoteMessageJoystickMoved;
      // 8 bytes additional data
      _numberOfAdditionalBytes = 8;

    } else if (byte == 'e') {
      // PHMoteMessageJoystickStopped 0 bytes additional data
      result = [[PHMoteState alloc] initWithJoystickDegrees:0 joystickTilt:0];

    } else {
      NSLog(@"Unknown message type: %c", byte);
    }

  } else if (_message == PHMoteMessageButton) {
    if (byte == 'a') {
      result = [[PHMoteState alloc] initWithATapped];
    } else if (byte == 'b') {
      result = [[PHMoteState alloc] initWithBTapped];
    }
    _message = PHMoteMessageUnknown;

  } else if (_message == PHMoteMessageHello) {
    if (byte > 0) {
      [_alias appendString:[NSString stringWithFormat:@"%c", byte]];
    } else {
      result = [_alias copy];
      _alias = nil;
      _message = PHMoteMessageUnknown;
    }

  } else {
    _additionalBytes[_numberOfReadBytes] = byte;
    _numberOfReadBytes++;

    if (_numberOfReadBytes == _numberOfAdditionalBytes) {
      if (_message == PHMoteMessageJoystickMoved) {
        float angle = *((float *)_additionalBytes);
        float tilt = *((float *)(_additionalBytes + 4));
        result = [[PHMoteState alloc] initWithJoystickDegrees:angle joystickTilt:tilt];
      }

      _message = PHMoteMessageUnknown;
    }
  }

  return result;
}

@end

@interface PHMoteThread : NSThread <NSStreamDelegate>
@property (nonatomic, readonly) NSMutableArray* moteSockets;
@end

void PHHandleHTTPConnection(CFSocketRef s, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info) {
  if (callbackType == kCFSocketAcceptCallBack) {
    CFSocketNativeHandle* socketHandle = (CFSocketNativeHandle *)data;

    CFReadStreamRef readStream;
    CFStreamCreatePairWithSocket(nil, *socketHandle, &readStream, nil);
    NSInputStream* inputStream = (__bridge NSInputStream *)readStream;

    PHMoteThread* thread = (__bridge PHMoteThread *)info;
    inputStream.delegate = thread;

    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream open];

    [thread.moteSockets addObject:inputStream];
  }
}

@implementation PHMoteThread {
  CFSocketRef _ipv4cfsock;
  CFRunLoopSourceRef _socketsource;
  NSMutableDictionary* _streamToState; // NSValue<(void *)NSStream> => PHMessageState
  NSMutableDictionary* _streamToMote; // NSValue<(void *)NSStream> => PHMote

  PHMoteMessage _currentMessage;
}

- (void)dealloc {
  if (nil != _ipv4cfsock) {
    CFSocketInvalidate(_ipv4cfsock);
    _ipv4cfsock = nil;
  }
  if (nil != _socketsource) {
    CFRunLoopSourceInvalidate(_socketsource);
    _socketsource = nil;
  }
}

- (id)init {
  if ((self = [super init])) {
    _moteSockets = [NSMutableArray array];
    _streamToMote = [NSMutableDictionary dictionary];
    _streamToState = [NSMutableDictionary dictionary];
  }
  return self;
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
  @synchronized(self) {
    if ([stream isKindOfClass:[NSInputStream class]]) {
      NSInputStream* inputStream = (NSInputStream *)stream;

      // The connection has been closed to a mote, remove it from the list.
      if (eventCode & NSStreamEventEndEncountered) {
        [_moteSockets removeObject:inputStream];
        id keyToRemove = nil;
        for (id key in _streamToMote) {
          PHMote* controller = [_streamToMote objectForKey:key];
          if (controller.stream == stream) {
            keyToRemove = key;
            break;
          }
        }
        if (nil != keyToRemove) {
          [_streamToMote removeObjectForKey:keyToRemove];
        }

      } else if (eventCode & NSStreamEventHasBytesAvailable) {
        uint8_t bytes[1024];
        memset(bytes, 0, sizeof(uint8_t) * 1024);
        NSInteger nread = [inputStream read:bytes maxLength:1023];
        // Null-terminate the string.
        bytes[nread] = 0;

        id<NSCopying> streamKey = [NSValue valueWithPointer:(__bridge void *)stream];
        PHMoteMessageState* state = [_streamToState objectForKey:streamKey];
        if (nil == state) {
          state = [[PHMoteMessageState alloc] init];
          [_streamToState setObject:state forKey:streamKey];
        }

        PHMote* mote = [_streamToMote objectForKey:streamKey];

        for (NSInteger ix = 0; ix < nread; ++ix) {
          uint8_t byte = bytes[ix];
          id result = [state readByte:byte];
          if ([result isKindOfClass:[PHMoteState class]]) {
            [mote addControllerState:result];

          } else if ([result isKindOfClass:[NSString class]]) {
            mote = [[PHMote alloc] initWithName:result stream:stream];
            [_streamToMote setObject:mote forKey:streamKey];
          }
        }
      }
    }
  }
}

- (NSArray *)allMotes {
  NSMutableArray* motes = [NSMutableArray array];
  @synchronized(self) {
    for (id key in _streamToMote) {
      PHMote* mote = [_streamToMote objectForKey:key];
      [motes addObject:[mote copy]];
    }
  }
  return motes;
}

- (void)didTick {
  @synchronized(self) {
    for (id key in _streamToMote) {
      PHMote* mote = [_streamToMote objectForKey:key];
      [mote tick];
    }
  }
}

- (void)startListening {
  CFSocketContext context;
  memset(&context, 0, sizeof(CFSocketContext));
  context.info = (__bridge void *)self;
  _ipv4cfsock = CFSocketCreate(kCFAllocatorDefault,
                               PF_INET,
                               SOCK_STREAM,
                               IPPROTO_TCP,
                               kCFSocketAcceptCallBack,
                               PHHandleHTTPConnection,
                               &context);
  if (nil == _ipv4cfsock) {
    NSLog(@"Failed to create socket");
    return;
  }
  struct sockaddr_in sin;

  memset(&sin, 0, sizeof(sin));
  sin.sin_len = sizeof(sin);
  sin.sin_family = AF_INET;
  sin.sin_port = htons(12345);
  sin.sin_addr.s_addr= INADDR_ANY;

  CFDataRef sincfd = CFDataCreate(kCFAllocatorDefault,
                                  (UInt8 *)&sin,
                                  sizeof(sin));

  CFSocketSetAddress(_ipv4cfsock, sincfd);
  CFRelease(sincfd);

  _socketsource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _ipv4cfsock, 0);
  if (nil == _socketsource) {
    NSLog(@"Failed to create socket source");
    CFSocketInvalidate(_ipv4cfsock);
    _ipv4cfsock = nil;
    return;
  }
  CFRunLoopAddSource(CFRunLoopGetCurrent(), _socketsource, kCFRunLoopDefaultMode);
}

- (void)main {
  [self startListening];

  CFRunLoopRun();
}

@end

@implementation PHMoteServer {
  PHMoteThread* _thread;
}

- (id)init {
  if ((self = [super init])) {
    _thread = [[PHMoteThread alloc] init];
    _thread.threadPriority = 0.7;
    [_thread start];
  }
  return self;
}

- (NSArray *)allMotes {
  return _thread.allMotes;
}

- (void)didTick {
  [_thread didTick];
}

@end
