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

#import "PHGameOfLifeAnimation.h"

#define WORLDOFFSETFROMXY(x, y) (((x) < 0 ? ((x) + kWallWidth) : ((x) % kWallWidth)) * 4 + ((y) < 0 ? ((y) + kWallHeight) : ((y) % kWallHeight)) * bytesPerRow)
#define ISCELLALIVEAT(x, y) ((_oldWorldBuffer[WORLDOFFSETFROMXY((x), (y)) + 3] == 255) ? 1 : 0)

static const NSTimeInterval kTimeBetweenTicks = 0.5;
static const NSTimeInterval kTimeUntilWorldRestarts = 1;

@implementation PHGameOfLifeAnimation {
  PHDegrader* _bassDegrader;
  
  CGContextRef _worldContextRef;
  unsigned char* _oldWorldBuffer;
  NSTimeInterval _lastTick;
  NSTimeInterval _deltaToNextTick;
  BOOL _shouldRestartWorld;
}

- (void)dealloc {
  if (_worldContextRef) {
    CGContextRelease(_worldContextRef);
  }
  if (_oldWorldBuffer) {
    free(_oldWorldBuffer);
  }
}

- (id)init {
  if ((self = [super init])) {
    _bassDegrader = [[PHDegrader alloc] init];

    _worldContextRef = PHCreate8BitBitmapContextWithSize(CGSizeMake(kWallWidth, kWallHeight));
    _oldWorldBuffer = malloc([self sizeOfBuffer]);

    [self initializeWorld];
  }
  return self;
}

- (size_t)sizeOfBuffer {
  size_t bytesPerRow = CGBitmapContextGetBytesPerRow(_worldContextRef);
  return sizeof(unsigned char) * bytesPerRow * kWallHeight;
}

- (void)initializeWorld {
  _shouldRestartWorld = NO;

  unsigned char* data = (unsigned char *)CGBitmapContextGetData(_worldContextRef);
  size_t bytesPerRow = CGBitmapContextGetBytesPerRow(_worldContextRef);

  for (NSInteger iy = 0; iy < kWallHeight; ++iy) {
    for (NSInteger ix = 0; ix < kWallWidth; ++ix) {
      NSInteger offset = ix * 4 + iy * bytesPerRow;

      BOOL isAlive = (arc4random_uniform(1000) < 200);
      data[offset + 0] = arc4random_uniform(128) + 128;
      data[offset + 1] = arc4random_uniform(128) + 128;
      data[offset + 2] = arc4random_uniform(128) + 128;
      data[offset + 3] = isAlive ? 255 : 0;
    }
  }
}

- (void)tickWorld {
  unsigned char* data = (unsigned char *)CGBitmapContextGetData(_worldContextRef);
  size_t bytesPerRow = CGBitmapContextGetBytesPerRow(_worldContextRef);

  memcpy(_oldWorldBuffer, data, [self sizeOfBuffer]);

  BOOL didChange = NO;
  for (NSInteger iy = 0; iy < kWallHeight; ++iy) {
    for (NSInteger ix = 0; ix < kWallWidth; ++ix) {
      NSInteger offset = WORLDOFFSETFROMXY(ix, iy);

      BOOL isAlive = (_oldWorldBuffer[offset + 3] == 255);
      NSInteger numberOfNeighbors = 0;
      // Left
      numberOfNeighbors += ISCELLALIVEAT(ix - 1, iy);

      // Top left
      numberOfNeighbors += ISCELLALIVEAT(ix - 1, iy - 1);

      // Bottom left
      numberOfNeighbors += ISCELLALIVEAT(ix - 1, iy + 1);

      // Right
      numberOfNeighbors += ISCELLALIVEAT(ix + 1, iy);

      // Top right
      numberOfNeighbors += ISCELLALIVEAT(ix + 1, iy - 1);

      // Bottom right
      numberOfNeighbors += ISCELLALIVEAT(ix + 1, iy + 1);

      // Top
      numberOfNeighbors += ISCELLALIVEAT(ix, iy - 1);
      // Bottom
      numberOfNeighbors += ISCELLALIVEAT(ix, iy + 1);

      if (isAlive) {
        if (numberOfNeighbors < 2 || numberOfNeighbors >= 4) {
          // Any live cell with fewer than two live neighbours dies, as if caused by under-population.
          // Any live cell with more than three live neighbours dies, as if by overcrowding.
          data[offset + 3] = 0;
          didChange = YES;

        } // else any live cell with two or three live neighbours lives on to the next generation.

      } else if (numberOfNeighbors == 3) {
        // Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
        data[offset + 3] = 255;
        didChange = YES;
      }
    }
  }

  if (!didChange) {
    _shouldRestartWorld = YES;
    _lastTick = [NSDate timeIntervalSinceReferenceDate];
    _deltaToNextTick = kTimeUntilWorldRestarts;
  } else {
    _lastTick = [NSDate timeIntervalSinceReferenceDate];
    _deltaToNextTick = kTimeBetweenTicks;
  }
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  if (self.driver.spectrum) {
    [_bassDegrader tickWithPeak:self.driver.subBassAmplitude];

    if (_bassDegrader.value > 0.1 && [NSDate timeIntervalSinceReferenceDate] >= _lastTick + _deltaToNextTick * (1 - _bassDegrader.value)) {
      if (_shouldRestartWorld) {
        [self initializeWorld];
      } else {
        [self tickWorld];
      }
    }

    CGImageRef imageRef = CGBitmapContextCreateImage(_worldContextRef);
    CGContextDrawImage(cx, CGRectMake(0, 0, size.width, size.height), imageRef);
    CGImageRelease(imageRef);
  }
}

@end
