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

#import "PHProcessingServer.h"

#include <CoreFoundation/CoreFoundation.h>
#include <sys/socket.h>
#include <netinet/in.h>

static NSInteger kMaxPacketSize = 1024 * 4;

@interface PHProcessingThread : NSThread <NSStreamDelegate>
@property (nonatomic, readonly) NSMutableArray* sockets;
@end

void PHHandleProcessingHTTPConnection(CFSocketRef s, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info) {
  if (callbackType == kCFSocketAcceptCallBack) {
    CFSocketNativeHandle* socketHandle = (CFSocketNativeHandle *)data;

    CFReadStreamRef readStream;
    CFStreamCreatePairWithSocket(nil, *socketHandle, &readStream, nil);
    NSInputStream* inputStream = (__bridge NSInputStream *)readStream;

    PHProcessingThread* thread = (__bridge PHProcessingThread *)info;
    inputStream.delegate = thread;

    NSLog(@"Connection created");

    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream open];

    [thread.sockets addObject:inputStream];
  }
}

@implementation PHProcessingThread {
  CFSocketRef _ipv4cfsock;
  CFRunLoopSourceRef _socketsource;
}

- (void)dealloc {
  for (NSStream* stream in _sockets) {
    [stream close];
  }
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
    _sockets = [NSMutableArray array];
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
        [stream close];
        [_sockets removeObject:stream];
        NSLog(@"Died");

      } else if (eventCode & NSStreamEventHasBytesAvailable) {
        uint8_t bytes[kMaxPacketSize];
        memset(bytes, 0, sizeof(uint8_t) * kMaxPacketSize);
        NSInteger nread = [inputStream read:bytes maxLength:kMaxPacketSize - 1];
        // Null-terminate the string.
        int nPixels;
        memcpy(&nPixels, bytes, sizeof(int));
        NSLog(@"%d", nPixels);
        bytes[nread] = 0;
        NSLog(@"%s", bytes);
      }
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
                               PHHandleProcessingHTTPConnection,
                               &context);
  if (nil == _ipv4cfsock) {
    NSLog(@"Failed to create socket");
    return;
  }
  struct sockaddr_in sin;

  memset(&sin, 0, sizeof(sin));
  sin.sin_len = sizeof(sin);
  sin.sin_family = AF_INET;
  sin.sin_port = htons(54000);
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

@implementation PHProcessingServer {
  PHProcessingThread* _thread;
}

- (id)init {
  if ((self = [super init])) {
    _thread = [[PHProcessingThread alloc] init];
    _thread.threadPriority = 0.7;
    [_thread start];
  }
  return self;
}

@end
