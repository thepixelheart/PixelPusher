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

#import "PHDriver.h"

#import "PHUSBNotifier.h"
#import "p9813.h"
#import "Utilities.h"

NSString* const PHDriverConnectionStateDidChangeNotification = @"PHDriverConnectionStateDidChangeNotification";

// Dimensions
const NSInteger kTileWidth = 16;
const NSInteger kTileHeight = 16;
const NSInteger kWallWidth = 48;
const NSInteger kWallHeight = 32;

// Pixels
static const NSInteger kNumberOfStrands = 6;
static const NSInteger kPixelsPerStrand = kTileWidth * kTileHeight;
static const NSInteger kNumberOfPixels = kNumberOfStrands * kPixelsPerStrand;

#define PHStrandIndexFromXY(x, y) ((x) * kTileHeight + (((x) % 2) ? ((kTileHeight - 1) - (y)) : (y)))
#define PHPixelMapIndexFromTopXY(x, y) ((x) + (y) * kWallWidth)
#define PHPixelMapIndexFromBottomXY(x, y) ((((kTileHeight - 1) - (y)) + kTileHeight) * kWallWidth + (x))
#define PHPixelIndexFromXY(x, y) ((x) + (y) * kWallWidth)

@interface PHPixelPusherOperation : NSOperation
- (id)initWithPixelMap:(int *)pixelMap stats:(TCstats *)stats;
@property (nonatomic, assign) CGContextRef context;
@property (nonatomic, readonly) int *pixelMap;
@property (nonatomic, readonly) TCstats *stats;
@end

@implementation PHPixelPusherOperation

- (void)dealloc {
  CGContextRelease(_context);
}

- (id)initWithPixelMap:(int *)pixelMap stats:(TCstats *)stats {
  if ((self = [super init])) {
    _pixelMap = pixelMap;
    _stats = stats;
  }
  return self;
}

- (void)main {
  // Allocate the pixel buffer.
  size_t sizeOfPixelBuffer = kNumberOfPixels * sizeof(TCpixel);
  TCpixel *pixelBuffer = (TCpixel *)malloc(sizeOfPixelBuffer);
  if (nil == pixelBuffer) {
    NSLog(@"Failed to create memory for pixel frame.");
    return;
  }
  memset(pixelBuffer, 0, sizeOfPixelBuffer);

  if (_context) {
    float* data = (float *)CGBitmapContextGetData(_context);
    size_t bytesPerRow = CGBitmapContextGetBytesPerRow(_context);

    for (NSInteger iy = 0; iy < kWallHeight; ++iy) {
      for (NSInteger ix = 0; ix < kWallWidth; ++ix) {
        NSInteger pixelIndex = PHPixelIndexFromXY(ix, iy);
        NSInteger offset = ix * 4 + (kWallHeight - 1 - iy) * (bytesPerRow / 4);

        float redFloat = data[offset];
        float greenFloat = data[offset + 1];
        float blueFloat = data[offset + 2];
        int red = (int)roundf(redFloat * 255.f);
        int green = (int)roundf(greenFloat * 255.f);
        int blue = (int)roundf(blueFloat * 255.f);
        red = MAX(0, MIN(255, red));
        green = MAX(0, MIN(255, green));
        blue = MAX(0, MIN(255, blue));
        pixelBuffer[pixelIndex] = TCrgb(red, green, blue);
      }
    }
  }

  TCstatusCode result = TCrefresh(pixelBuffer, _pixelMap, _stats);
  if (result != TC_OK) {
    NSLog(@"Failed to refresh");
  }
  free(pixelBuffer);
}

- (void)setContext:(CGContextRef)context {
  if (_context == context) {
    return;
  }
  if (nil != _context) {
    CGContextRelease(_context);
  }
  _context = CGContextRetain(context);
}

@end

@implementation PHDriver {
  int *_pixelMap;
  size_t _sizeOfPixelMap;

	TCstats _stats;
  NSOperationQueue *_operationQueue;
}

- (void)dealloc {
  if (_connected) {
    TCclose();
  }
  free(_pixelMap);
}

- (id)init {
  if ((self = [super init])) {
    _operationQueue = [[NSOperationQueue alloc] init];
    // We only want one thread talking to the wall at a time.
    _operationQueue.maxConcurrentOperationCount = 1;

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(ft232ConnectionStateDidChange)
               name:PHFT232ConnectionStateDidChangeNotification
             object:nil];

    // Allocate the pixel map.
    _sizeOfPixelMap = kNumberOfPixels * sizeof(int);
    _pixelMap = (int *)malloc(_sizeOfPixelMap);
    if (nil == _pixelMap) {
      PHAlert(@"Unable to allocate pixel map");
      self = nil;
      return self;
    }
    memset(_pixelMap, 0, _sizeOfPixelMap);


    // Set up the pixel map.
    // 0,0 is the top left pixel.

    for (int iy = 0; iy < kTileHeight; ++iy) {
      for (int ix = 0; ix < kTileWidth; ++ix) {
        // Pin 0 top right
        int strandIndex = PHStrandIndexFromXY(ix, iy);
        int pixelIndex = PHPixelMapIndexFromTopXY(ix + kTileWidth * 2, iy);
        _pixelMap[strandIndex] = pixelIndex;

        // Pin 1 bottom right
        strandIndex = PHStrandIndexFromXY(ix, iy) + kPixelsPerStrand;
        pixelIndex = PHPixelMapIndexFromBottomXY(ix + kTileWidth * 2, iy);
        _pixelMap[strandIndex] = pixelIndex;

        // Pin 2 top middle
        strandIndex = PHStrandIndexFromXY(ix, iy) + kPixelsPerStrand * 2;
        pixelIndex = PHPixelMapIndexFromTopXY(ix + kTileWidth, iy);
        _pixelMap[strandIndex] = pixelIndex;

        // Pin 3 bottom middle
        strandIndex = PHStrandIndexFromXY(ix, iy) + kPixelsPerStrand * 3;
        pixelIndex = PHPixelMapIndexFromBottomXY(ix + kTileWidth, iy);
        _pixelMap[strandIndex] = pixelIndex;

        // Pin 4 top left
        strandIndex = PHStrandIndexFromXY(ix, iy) + kPixelsPerStrand * 4;
        pixelIndex = PHPixelMapIndexFromTopXY(ix, iy);
        _pixelMap[strandIndex] = pixelIndex;

        // Pin 5 bottom left
        strandIndex = PHStrandIndexFromXY(ix, iy) + kPixelsPerStrand * 5;
        pixelIndex = PHPixelMapIndexFromBottomXY(ix, iy);
        _pixelMap[strandIndex] = pixelIndex;
      }
    }

    [self attemptFTDIConnection];
  }
  return self;
}

- (BOOL)attemptFTDIConnection {
  if (_connected) {
    return YES;
  }

  // Disable gamma correction.
  TCsetGammaSimple(1);

  // Open the connection to the FTDI adapter.
  TCstatusCode result = TCopen(kNumberOfStrands, kPixelsPerStrand);
  if (result != TC_OK && result < TC_ERR_DIVISOR) {
    return NO;
  }

  // Map the pins.
  TCsetStrandPin(0, TC_FTDI_TX);
  TCsetStrandPin(1, TC_FTDI_RX);
  TCsetStrandPin(2, TC_FTDI_RTS);
  TCsetStrandPin(3, TC_FTDI_DTR);
  TCsetStrandPin(4, TC_FTDI_DCD);
  TCsetStrandPin(5, TC_FTDI_DSR);

  TCinitStats(&_stats);

  _connected = YES;
  return YES;
}

#pragma mark - FT232 Connection State

- (void)ft232ConnectionStateDidChange {
  if (_connected) {
    TCclose();
    _connected = NO;
  }

  [self attemptFTDIConnection];

  [[NSNotificationCenter defaultCenter] postNotificationName:PHDriverConnectionStateDidChangeNotification
                                                      object:nil];
}

#pragma mark - Public Methods

- (void)queueContext:(CGContextRef)context {
  NSArray* operations = [_operationQueue.operations copy];
  for (NSOperation* op in operations) {
    if (op != [operations objectAtIndex:0]) {
      [op cancel];
    }
  }

  if ([self isConnected]) {
    PHPixelPusherOperation *pusherOp = [[PHPixelPusherOperation alloc] initWithPixelMap:_pixelMap
                                                                                  stats:&_stats];
    pusherOp.context = context;
    [_operationQueue addOperation:pusherOp];
  }
}

@end
