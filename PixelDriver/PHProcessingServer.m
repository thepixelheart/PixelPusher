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

#import "Utilities.h"

#include <CoreFoundation/CoreFoundation.h>
#include <sys/socket.h>
#include <netinet/in.h>

static NSInteger kMaxPacketSize = 1024 * 8;
#define PHBYTESPERFRAME ((1 + 48 * 32) * 4) // 1 for number of pixels + 48 * 32 pixels

@interface PHProcessingState : NSObject
@end

@implementation PHProcessingState {
  uint8_t _data[PHBYTESPERFRAME];
  uint8_t* _dataOffset;
}

- (id)init {
  if ((self = [super init])) {
    _dataOffset = _data;
  }
  return self;
}

- (CGContextRef)readBytes:(uint8_t *)bytes numberOfBytes:(NSInteger)numberOfBytes {
  NSLog(@"Reading bytes: %ld", numberOfBytes);
  NSInteger offsetInBytes = _dataOffset - _data;

  CGContextRef bitmapRef = nil;
  while (numberOfBytes > 0) {
    if (offsetInBytes + numberOfBytes >= PHBYTESPERFRAME) {
      // End of a frame.
      NSInteger numberOfBytesRemaining = PHBYTESPERFRAME - offsetInBytes;
      memcpy(_dataOffset, bytes, sizeof(uint8_t) * numberOfBytesRemaining);
      _dataOffset = _data;

      // We've read this many bytes, start consuming the next frame.
      bytes += numberOfBytesRemaining;
      numberOfBytes -= numberOfBytesRemaining;

      int numberOfPixels;
      memcpy(&numberOfPixels, _data, sizeof(int));
      if (numberOfPixels == 1536) {
        if (nil != bitmapRef) {
          // TODO: Figure out when to create the bitmap more efficiently in case
          // we get a shit ton of data all at once.
          NSLog(@"Dropping bitmap context :(");
          CGContextRelease(bitmapRef);
        }

        // Valid frame, w00t.
        bitmapRef = PHCreate8BitBitmapContextWithSize(CGSizeMake(48, 32));
        unsigned char* bitmapData = (unsigned char *)CGBitmapContextGetData(bitmapRef);

        // Flip the bytes of the bitmap data.
        for (NSInteger pixelOffset = 0; pixelOffset < numberOfBytes; pixelOffset += 4) {
          bitmapData[pixelOffset + 0] = _data[pixelOffset + 1];
          bitmapData[pixelOffset + 1] = _data[pixelOffset + 2];
          bitmapData[pixelOffset + 2] = _data[pixelOffset + 3];
          bitmapData[pixelOffset + 3] = _data[pixelOffset + 0];
        }
      }

    } else {
      // Not going to fill the buffer, just copy it all in.
      memcpy(_dataOffset, bytes, sizeof(uint8_t) * numberOfBytes);
      _dataOffset += numberOfBytes;
      numberOfBytes = 0;
    }
  }
  return bitmapRef;
}

@end

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
  NSMutableDictionary* _streamToState; // NSValue<(void *)NSStream> => PHProcessingState
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
        NSLog(@"Connection closed");

        id<NSCopying> streamKey = [NSValue valueWithPointer:(__bridge void *)stream];
        [_streamToState removeObjectForKey:streamKey];

        [stream close];
        [_sockets removeObject:stream];

      } else if (eventCode & NSStreamEventHasBytesAvailable) {
        uint8_t bytes[kMaxPacketSize];
        memset(bytes, 0, sizeof(uint8_t) * kMaxPacketSize);
        NSInteger nread = [inputStream read:bytes maxLength:kMaxPacketSize];

        id<NSCopying> streamKey = [NSValue valueWithPointer:(__bridge void *)stream];
        PHProcessingState* state = [_streamToState objectForKey:streamKey];
        if (nil == state) {
          state = [[PHProcessingState alloc] init];
          [_streamToState setObject:state forKey:streamKey];
        }

        if (nread > 0) {
          CGContextRef bitmapRef = [state readBytes:bytes numberOfBytes:nread];
          if (nil != bitmapRef) {
            NSLog(@"Created bitmap");
            CGContextRelease(bitmapRef);
          }
        }
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
