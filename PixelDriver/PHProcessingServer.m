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

#import "PHDriver.h"
#import "PHProcessingSource.h"
#import "Utilities.h"

#include <CoreFoundation/CoreFoundation.h>
#include <sys/socket.h>
#include <netinet/in.h>

NSString* const PHProcessingSourceListDidChangeNotification = @"PHProcessingSourceListDidChangeNotification";

static NSInteger kMaxPacketSize = 1024 * 8;
#define PHBYTESPERFRAME ((1 + 48 * 32) * 4) // 1 for number of pixels + 48 * 32 pixels

@interface PHProcessingState : NSObject
@property (nonatomic, readonly, strong) PHProcessingSource* source;
@end

@implementation PHProcessingState {
  uint8_t _data[PHBYTESPERFRAME];
  uint8_t* _dataOffset;
}

- (id)init {
  if ((self = [super init])) {
    _dataOffset = _data;
    _source = [[PHProcessingSource alloc] init];
    _source.identifier = [NSString stringWithFormat:@"%ld", (unsigned long)self];
  }
  return self;
}

- (void)readBytes:(uint8_t *)bytes numberOfBytes:(NSInteger)numberOfBytes {
  if (nil == _source.name) {
    while (nil == _source.name && numberOfBytes > 0) {
      *_dataOffset = *bytes;
      ++_dataOffset;

      if ((*bytes) == 0) {
        _source.name = [[NSString alloc] initWithCString:(char *)_data encoding:NSUTF8StringEncoding];
        _dataOffset = _data;

        NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:PHProcessingSourceListDidChangeNotification object:nil];
      }

      --numberOfBytes;
      ++bytes;
    }
  }

  NSInteger offsetInBytes = _dataOffset - _data;

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
      if (numberOfPixels == (kWallWidth * kWallHeight)) {
        // Valid frame, w00t.
        CGContextRef bitmapRef = PHCreate8BitBitmapContextWithSize(CGSizeMake(kWallWidth, kWallHeight));
        unsigned char* bitmapData = (unsigned char *)CGBitmapContextGetData(bitmapRef);

        // Flip the bytes of the bitmap data from ARGB to RGBA.
        // TODO: Do we need to premultiply the alpha?
        for (NSInteger pixelOffset = 0; pixelOffset < numberOfPixels * 4; pixelOffset += 4) {
          bitmapData[pixelOffset + 0] = _data[pixelOffset + 2 + 4]; // red
          bitmapData[pixelOffset + 1] = _data[pixelOffset + 1 + 4]; // green
          bitmapData[pixelOffset + 2] = _data[pixelOffset + 0 + 4]; // blue
          bitmapData[pixelOffset + 3] = _data[pixelOffset + 3 + 4]; // alpha
        }

        [_source updateImageWithContextRef:bitmapRef];
        CGContextRelease(bitmapRef);
      }

    } else {
      // Not going to fill the buffer, just copy it all in.
      memcpy(_dataOffset, bytes, sizeof(uint8_t) * numberOfBytes);
      _dataOffset += numberOfBytes;
      numberOfBytes = 0;
    }
  }
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
        id<NSCopying> streamKey = [NSValue valueWithPointer:(__bridge void *)stream];
        [_streamToState removeObjectForKey:streamKey];

        [stream close];
        [_sockets removeObject:stream];

        NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:PHProcessingSourceListDidChangeNotification object:nil];

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
          [state readBytes:bytes numberOfBytes:nread];
        }
      }
    }
  }
}

- (NSArray *)allSources {
  NSMutableArray* sources = [NSMutableArray array];
  @synchronized(self) {
    NSArray* allStates = [_streamToState allValues];

    for (PHProcessingState* state in allStates) {
      [sources addObject:state.source];
    }
  }
  return sources;
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

- (NSArray *)allSources {
  return _thread.allSources;
}

@end
