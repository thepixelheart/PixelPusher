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
static const NSInteger kTileWidth = 16;
static const NSInteger kTileHeight = 16;
const NSInteger kWallWidth = 48;
const NSInteger kWallHeight = 32;

// Pixels
static const NSInteger kNumberOfStrands = 6;
static const NSInteger kPixelsPerStrand = kTileWidth * kTileHeight;
static const NSInteger kNumberOfPixels = kNumberOfStrands * kPixelsPerStrand;

#define PHStrandIndexFromXY(x, y) ((x) * kTileHeight + (((x) % 2) ? ((kTileHeight - 1) - (y)) : (y)))
#define PHPixelMapIndexFromTopXY(x, y) ((y) * kWallWidth + (x))
#define PHPixelMapIndexFromBottomXY(x, y) ((((kTileHeight - 1) - (y)) + kTileHeight) * kWallWidth + (x))

@implementation PHDriver {
  TCpixel *_pixelBuffer;
  size_t _sizeOfPixelBuffer;
  int *_pixelMap;
  size_t _sizeOfPixelMap;

	TCstats _stats;
}

- (void)dealloc {
  if (_connected) {
    TCclose();
  }
	free(_pixelBuffer);
  free(_pixelMap);
}

- (id)init {
  if ((self = [super init])) {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(ft232ConnectionStateDidChange)
               name:PHFT232ConnectionStateDidChangeNotification
             object:nil];

    // Allocate the pixel buffer.
    _sizeOfPixelBuffer = kNumberOfPixels * sizeof(TCpixel);
    _pixelBuffer = (TCpixel *)malloc(_sizeOfPixelBuffer);
    if (nil == _pixelBuffer) {
      PHAlert(@"Unable to allocate pixel buffer");
      self = nil;
      return self;
    }
    memset(_pixelBuffer, 0, _sizeOfPixelBuffer);


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

@end
