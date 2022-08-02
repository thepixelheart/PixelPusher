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

@implementation PHDriver {
  int *_pixelMap;
  size_t _sizeOfPixelMap;

  NSOperationQueue *_operationQueue;
}

- (void)dealloc {
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
  }
  return self;
}

#pragma mark - Public Methods

- (void)queueContext:(CGContextRef)context {
  NSArray* operations = [_operationQueue.operations copy];
  for (NSOperation* op in operations) {
    if (op != [operations objectAtIndex:0]) {
      [op cancel];
    }
  }
}

@end
