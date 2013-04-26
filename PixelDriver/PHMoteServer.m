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

#import "AppDelegate.h"
#import "PHAnimation.h"
#import "PHSystem.h"
#import "PHDisplayLink.h"
#import "PHSystemTick.h"

#import "PHMote.h"
#import "PHMote+Private.h"
#import "PHMoteState+Private.h"

#include <CoreFoundation/CoreFoundation.h>
#include <sys/socket.h>
#include <netinet/in.h>

static NSInteger kMaxPacketSize = 1024 * 4;

typedef enum {
  PHMoteMessageHello,
  PHMoteMessageButtonPressed,
  PHMoteMessageButtonReleased,
  PHMoteMessageJoystickMoved,
  PHMoteMessageJoystickStopped,
  PHMoteMessageXYPoint,
  PHMoteMessageText,
  PHMoteMessageControl,
  PHMoteMessageUnknown
} PHMoteMessage;

@interface PHMoteMessageState : NSObject
@end

@implementation PHMoteMessageState {
  PHMoteMessage _message;
  NSInteger _numberOfAdditionalBytes;
  NSInteger _numberOfReadBytes;
  uint8_t _additionalBytes[256];
  NSMutableString* _alias;
  NSMutableString* _text;
}

- (id)init {
  if ((self = [super init])) {
    _message = PHMoteMessageUnknown;
  }
  return self;
}

- (id)readByte:(uint8_t)byte latestState:(PHMoteState *)latestState {
  if (nil == latestState) {
    latestState = [[PHMoteState alloc] init];
  }

  id result = nil;

  if (_message == PHMoteMessageUnknown) {
    _numberOfReadBytes = 0;

    if (byte == 'h') {
      _message = PHMoteMessageHello;
      _alias = [NSMutableString string];

    } else if (byte == 'p') {
      _message = PHMoteMessageButtonPressed;
      // 1 byte additional data: 'a' or 'b'

    } else if (byte == 'r') {
      _message = PHMoteMessageButtonReleased;
      // 1 byte additional data: 'a' or 'b'

    } else if (byte == 'm') {
      _message = PHMoteMessageJoystickMoved;
      // 8 bytes additional data
      _numberOfAdditionalBytes = 8;

    } else if (byte == 'e') {
      // PHMoteMessageJoystickStopped 0 bytes additional data
      result = [[PHMoteState alloc] init];

    } else if (byte == 't') {
      _message = PHMoteMessageText;
      _text = [NSMutableString string];

    } else if (byte == 'c') {
      _message = PHMoteMessageControl;

    } else if (byte == 'x') {
      _message = PHMoteMessageXYPoint;
      _numberOfAdditionalBytes = 2;

    } else {
      NSLog(@"Unknown message type: %c", byte);
    }

  } else if (_message == PHMoteMessageControl) {
    if (byte == 'l') {
      PHMoteState* state = [latestState copy];
      state.controlEvent = PHMoteStateControlEventListAnimations;
      result = state;
    } else if (byte == '+') {
      PHMoteState* state = [latestState copy];
      state.controlEvent = PHMoteStateControlEventStartStreaming;
      result = state;
    } else if (byte == '-') {
      PHMoteState* state = [latestState copy];
      state.controlEvent = PHMoteStateControlEventStopStreaming;
      result = state;
    }
    _message = PHMoteMessageUnknown;

  } else if (_message == PHMoteMessageButtonPressed) {
    if (byte == 'a') {
      PHMoteState* state = [latestState copy];
      state.aIsTapped = YES;
      result = state;

    } else if (byte == 'b') {
      PHMoteState* state = [latestState copy];
      state.bIsTapped = YES;
      result = state;
    }
    _message = PHMoteMessageUnknown;

  } else if (_message == PHMoteMessageButtonReleased) {
    if (byte == 'a') {
      PHMoteState* state = [latestState copy];
      state.aIsTapped = NO;
      result = state;

    } else if (byte == 'b') {
      PHMoteState* state = [latestState copy];
      state.bIsTapped = NO;
      result = state;
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

  } else if (_message == PHMoteMessageText) {
    if (byte > 0) {
      [_text appendString:[NSString stringWithFormat:@"%c", byte]];
    } else {
      PHMoteState* state = [latestState copy];
      state.text = _text;
      result = state;
      _text = nil;
      _message = PHMoteMessageUnknown;
    }
    
  } else {
    _additionalBytes[_numberOfReadBytes] = byte;
    _numberOfReadBytes++;

    if (_numberOfReadBytes == _numberOfAdditionalBytes) {
      if (_message == PHMoteMessageJoystickMoved) {
        float angle = *((float *)_additionalBytes);
        float tilt = *((float *)(_additionalBytes + 4));

        PHMoteState* state = [latestState copy];
        state.joystickDegrees = angle;
        state.joystickTilt = tilt;
        result = state;
      } else if (_message == PHMoteMessageXYPoint) {
        uint8_t y = _additionalBytes[0];
        uint8_t x = _additionalBytes[1];

        PHMoteState* state = [latestState copy];
        state.xy = CGPointMake(x, y);
        result = state;
      }

      _message = PHMoteMessageUnknown;
    }
  }

  return result;
}

@end

@interface PHMoteStreams : NSObject
@property (nonatomic, strong) PHMote* mote;
@property (nonatomic, strong) NSInputStream* inputStream;
@property (nonatomic, strong) NSOutputStream* outputStream;
@end

@implementation PHMoteStreams

- (void)dealloc {
  [_inputStream close];
  [_outputStream close];
}

@end

@interface PHMoteThread : NSThread <NSStreamDelegate, NSNetServiceDelegate, NSNetServiceBrowserDelegate> {
  NSNetService *_service;
  NSNetServiceBrowser* _browser;
  uint16_t _port;
}
@property (nonatomic, readonly) NSMutableArray* moteSockets;
@end

void PHHandleHTTPConnection(CFSocketRef s, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info) {
  if (callbackType == kCFSocketAcceptCallBack) {
    CFSocketNativeHandle* socketHandle = (CFSocketNativeHandle *)data;

    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocket(nil, *socketHandle, &readStream, &writeStream);
    NSInputStream* inputStream = (__bridge NSInputStream *)readStream;
    NSOutputStream* outputStream = (__bridge NSOutputStream *)writeStream;

    PHMoteThread* thread = (__bridge PHMoteThread *)info;
    inputStream.delegate = thread;
    outputStream.delegate = thread;

    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream open];

    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream open];
    
    PHMoteStreams* streams = [[PHMoteStreams alloc] init];
    streams.inputStream = inputStream;
    streams.outputStream = outputStream;

    [thread.moteSockets addObject:streams];
  }
}

@implementation PHMoteThread {
  CFSocketRef _ipv4cfsock;
  CFRunLoopSourceRef _socketsource;
  NSMutableDictionary* _streamToState; // NSValue<(void *)NSStream> => PHMessageState
  NSMutableDictionary* _streamToMote; // NSValue<(void *)NSStream> => PHMote
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
  [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (void)sendAnimationListToStream:(PHMoteStreams *)streams {
  NSArray* allAnimations = [PHSys() compiledAnimations];
  NSMutableArray* animationDicts = [NSMutableArray array];
  for (PHAnimation* animation in allAnimations) {
    CGSize wallSize = CGSizeMake(kWallWidth, kWallHeight);
    CGContextRef contextRef = PHCreate8BitBitmapContextWithSize(wallSize);
    [animation renderPreviewInContext:contextRef size:wallSize];

    CGImageRef previewImageRef = CGBitmapContextCreateImage(contextRef);
    CGContextRelease(contextRef);

    NSImage* image = [[NSImage alloc] initWithCGImage:previewImageRef size:wallSize];
    CGImageRelease(previewImageRef);

    [animationDicts addObject:@{
     @"name": animation.tooltipName,
     @"image": [image TIFFRepresentation]}];
  }

  NSMutableData *data = [[NSMutableData alloc] init];
  NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
  [archiver encodeObject:animationDicts];
  [archiver finishEncoding];

  NSMutableData *message = [[NSMutableData alloc] initWithData:[@"l" dataUsingEncoding:NSUTF8StringEncoding]];
  int32_t length = (int32_t)(data.length);
  [message appendBytes:&length length:sizeof(int32_t)];
  [message appendData:data];
  NSInteger bytesWritten = 0;
  while (bytesWritten < message.length) {
    bytesWritten += [streams.outputStream write:[message bytes] + bytesWritten maxLength:[message length] - bytesWritten];
  }
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
  @synchronized(self) {
    if ([stream isKindOfClass:[NSInputStream class]]) {
      NSInputStream* inputStream = (NSInputStream *)stream;

      // The connection has been closed to a mote, remove it from the list.
      if (eventCode & NSStreamEventEndEncountered) {
        id<NSCopying> streamKey = [NSValue valueWithPointer:(__bridge void *)stream];
        [_streamToMote removeObjectForKey:streamKey];
        [_streamToState removeObjectForKey:streamKey];

        [stream close];

        NSArray* allStreams = [_moteSockets copy];
        for (PHMoteStreams* streams in allStreams) {
          if (streams.inputStream == stream
              || streams.outputStream == stream) {
            [_moteSockets removeObject:streams];
          }
        }

      } else if (eventCode & NSStreamEventHasBytesAvailable) {
        uint8_t bytes[kMaxPacketSize];
        memset(bytes, 0, sizeof(uint8_t) * kMaxPacketSize);
        NSInteger nread = [inputStream read:bytes maxLength:kMaxPacketSize];

        id<NSCopying> streamKey = [NSValue valueWithPointer:(__bridge void *)stream];
        PHMoteMessageState* state = [_streamToState objectForKey:streamKey];
        if (nil == state) {
          state = [[PHMoteMessageState alloc] init];
          [_streamToState setObject:state forKey:streamKey];
        }

        PHMote* mote = [_streamToMote objectForKey:streamKey];

        for (NSInteger ix = 0; ix < nread; ++ix) {
          uint8_t byte = bytes[ix];
          id result = [state readByte:byte latestState:mote.lastState];
          if ([result isKindOfClass:[PHMoteState class]]) {
            PHMoteState* state = result;
            if (state.controlEvent == PHMoteStateControlEventListAnimations) {
              for (PHMoteStreams* streams in _moteSockets) {
                if (streams.inputStream == stream) {
                  [self sendAnimationListToStream:streams];
                  break;
                }
              }

            } else {
              [mote addControllerState:result];
            }

          } else if ([result isKindOfClass:[NSString class]]) {
            NSArray* parts = [result componentsSeparatedByString:@","];
            NSString* name = [[parts subarrayWithRange:NSMakeRange(1, parts.count - 1)] componentsJoinedByString:@","];
            mote = [[PHMote alloc] initWithName:name identifier:parts[0] stream:stream];
            for (PHMoteStreams* streams in _moteSockets) {
              if (streams.inputStream == stream) {
                streams.mote = mote;
                break;
              }
            }
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

- (void)didTickWithContextValue:(NSData *)message {
  for (PHMoteStreams* streams in _moteSockets) {
    if (streams.mote.streaming) {
      if (streams.outputStream.streamStatus == NSStreamStatusOpen
          && streams.outputStream.hasSpaceAvailable) {
        NSInteger bytesWritten = 0;
        while (bytesWritten < message.length) {
          bytesWritten += [streams.outputStream write:[message bytes] + bytesWritten maxLength:[message length] - bytesWritten];
        }
      }
    }
  }
}

- (void)displayLinkDidFire:(NSNotification *)notification {
  PHSystemTick* systemTick = notification.userInfo[PHDisplayLinkFiredSystemTickKey];

  BOOL anyStreaming = NO;
  for (PHMoteStreams* streams in _moteSockets) {
    if (streams.mote.streaming && streams.outputStream.streamStatus == NSStreamStatusOpen
        && streams.outputStream.hasSpaceAvailable) {
      anyStreaming = YES;
    }
  }
  if (!anyStreaming) {
    return;
  }

  CGSize wallSize = CGSizeMake(kWallWidth, kWallHeight);
  CGContextRef contextRef = PHCreate8BitBitmapContextWithSize(wallSize);

  CGImageRef imageRef = CGBitmapContextCreateImage(systemTick.wallContextRef);
  CGContextDrawImage(contextRef, CGRectMake(0, 0, wallSize.width, wallSize.height), imageRef);
  CGImageRelease(imageRef);

  imageRef = CGBitmapContextCreateImage(contextRef);
  CGContextRelease(contextRef);

  NSImage* image = [[NSImage alloc] initWithCGImage:imageRef size:CGSizeMake(kWallWidth, kWallHeight)];
  CGImageRelease(imageRef);
  NSData* data = [image TIFFRepresentation];

  NSMutableData *message = [[NSMutableData alloc] initWithData:[@"~" dataUsingEncoding:NSUTF8StringEncoding]];
  int32_t length = (int32_t)(data.length);
  [message appendBytes:&length length:sizeof(int32_t)];
  [message appendData:data];
  [self performSelector:@selector(didTickWithContextValue:) onThread:self withObject:message waitUntilDone:NO];
}

- (void)startListening {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(displayLinkDidFire:) name:PHDisplayLinkFiredNotification object:nil];
  
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

  // Enable address reuse.
  int yes = 1;
  setsockopt(CFSocketGetNative(_ipv4cfsock),
             SOL_SOCKET, SO_REUSEADDR,
             (void *)&yes, sizeof(yes));

  // set the packet size for send and receive
  // cuts down on latency and such when sending
  // small packets
  uint8_t packetSize = 128;
  setsockopt(CFSocketGetNative(_ipv4cfsock),
             SOL_SOCKET, SO_SNDBUF,
             (void *)&packetSize, sizeof(packetSize));
  setsockopt(CFSocketGetNative(_ipv4cfsock),
             SOL_SOCKET, SO_RCVBUF,
             (void *)&packetSize, sizeof(packetSize));

  // set up the IPv4 endpoint; use port 0, so the kernel
  // will choose an arbitrary port for us, which will be
  // advertised through Bonjour
  struct sockaddr_in addr4;
  memset(&addr4, 0, sizeof(addr4));
  addr4.sin_len = sizeof(addr4);
  addr4.sin_family = AF_INET;
  addr4.sin_port = 0; // since we set it to zero the kernel will assign one for us
  addr4.sin_addr.s_addr = htonl(INADDR_ANY);

  NSData *address4 = [NSData dataWithBytes:&addr4 length:sizeof(addr4)];

  CFSocketSetAddress(_ipv4cfsock, (__bridge CFDataRef)address4);

  // Get the port
  NSData *addr = (__bridge NSData *)CFSocketCopyAddress(_ipv4cfsock);
  memcpy(&addr4, [addr bytes], [addr length]);
  _port = ntohs(addr4.sin_port);

  _socketsource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _ipv4cfsock, 0);
  if (nil == _socketsource) {
    NSLog(@"Failed to create socket source");
    CFSocketInvalidate(_ipv4cfsock);
    _ipv4cfsock = nil;
    return;
  }
  CFRunLoopAddSource(CFRunLoopGetCurrent(), _socketsource, kCFRunLoopDefaultMode);
  NSLog(@"port: %d", _port);

  _service = [[NSNetService alloc] initWithDomain:@"" type:@"_pixelmote._tcp." name:@"Pixel Mote Server" port:_port];
  _service.delegate = self;

  [_service scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
  [_service publish];
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
