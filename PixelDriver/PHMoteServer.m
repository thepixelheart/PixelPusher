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
  NSMutableDictionary* _streamToHangingMessage; // NSValue<(void *)NSStream> => NSString
  NSMutableDictionary* _moteIdToMote; // mote id => PHMote
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
    _moteIdToMote = [NSMutableDictionary dictionary];
    _streamToHangingMessage = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)processControllerMessage:(NSString *)message stream:(NSStream *)stream {
  NSArray* parts = [message componentsSeparatedByString:@":"];

  if (parts.count == 3) {
    NSString* command = parts[0];
    NSString* data = parts[1];
    NSString* who = parts[2];

    if ([command isEqualToString:@"hi"]) {
      PHMote* controller = [[PHMote alloc] initWithIdentifier:who stream:stream];
      controller.name = [[data componentsSeparatedByString:@","] lastObject];
      [_moteIdToMote setObject:controller forKey:who];

    } else {
      PHMote* controller = [_moteIdToMote objectForKey:who];
      PHMoteState* state = nil;
      if ([command isEqualToString:@"mv"]) {
        NSArray* parts = [data componentsSeparatedByString:@","];
        CGFloat degrees = [parts[0] doubleValue];
        CGFloat tilt = [parts[1] doubleValue];
        state = [[PHMoteState alloc] initWithJoystickDegrees:degrees joystickTilt:tilt];

      } else if ([command isEqualToString:@"emv"]) {
        state = [[PHMoteState alloc] initWithJoystickDegrees:0 joystickTilt:0];

      } else if ([command isEqualToString:@"bp"]) {
        NSInteger button = [data intValue];
        if (button == 0) {
          state = [[PHMoteState alloc] initWithATapped];
        } else if (button == 1) {
          state = [[PHMoteState alloc] initWithBTapped];
        }
      }

      [controller addControllerState:state];
    }
  }
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
  @synchronized(self) {
    if ([stream isKindOfClass:[NSInputStream class]]) {
      NSInputStream* inputStream = (NSInputStream *)stream;
      if (eventCode & NSStreamEventEndEncountered) {
        [_moteSockets removeObject:inputStream];
        NSString* keyToRemove = nil;
        for (NSString* key in _moteIdToMote) {
          PHMote* controller = [_moteIdToMote objectForKey:key];
          if (controller.stream == stream) {
            keyToRemove = key;
            break;
          }
        }
        if (nil != keyToRemove) {
          [_moteIdToMote removeObjectForKey:keyToRemove];
        }

      } else if (eventCode & NSStreamEventHasBytesAvailable) {
        uint8_t bytes[1024];
        memset(bytes, 0, sizeof(uint8_t) * 1024);
        NSInteger nread = [inputStream read:bytes maxLength:1023];
        // Null-terminate the string.
        bytes[nread] = 0;
        NSString* string = [NSString stringWithCString:(const char *)bytes encoding:NSUTF8StringEncoding];

        id<NSCopying> streamKey = [NSValue valueWithPointer:(__bridge void *)stream];
        NSString* hangingMessage = [_streamToHangingMessage objectForKey:streamKey];

        if (nil != hangingMessage) {
          string = [hangingMessage stringByAppendingString:string];
          [_streamToHangingMessage removeObjectForKey:streamKey];
        }

        NSArray* messages = [string componentsSeparatedByString:@"\n"];

        BOOL isComplete = [string hasSuffix:@"\n"];

        for (NSString* message in messages) {
          if (message == [messages lastObject] && !isComplete) {
            // Carry this over to the next stream event.
            [_streamToHangingMessage setObject:message forKey:streamKey];
            continue;
          }
          [self processControllerMessage:message stream:stream];
        }
      }
    }
  }
}

- (NSArray *)allMotes {
  NSMutableArray* motes = [NSMutableArray array];
  @synchronized(self) {
    for (NSString* key in _moteIdToMote) {
      PHMote* mote = [_moteIdToMote objectForKey:key];
      [motes addObject:[mote copy]];
    }
  }
  return motes;
}

- (void)didTick {
  @synchronized(self) {
    for (NSString* key in _moteIdToMote) {
      PHMote* mote = [_moteIdToMote objectForKey:key];
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
