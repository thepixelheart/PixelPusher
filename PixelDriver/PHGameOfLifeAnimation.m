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

      NSColor* color = generateRandomColor();
      CGFloat r,g,b,a;
      [color getRed:&r green:&g blue:&b alpha:&a];
      BOOL isAlive = (arc4random_uniform(1000) < 200);
      data[offset + 0] = r * 255;
      data[offset + 1] = g * 255;
      data[offset + 2] = b * 255;
      data[offset + 3] = isAlive ? 255 : 0;
    }
  }
}

- (void)addRandomLife {
  unsigned char* data = (unsigned char *)CGBitmapContextGetData(_worldContextRef);
  size_t bytesPerRow = CGBitmapContextGetBytesPerRow(_worldContextRef);

  NSInteger x = arc4random_uniform((u_int32_t)kWallWidth);
  NSInteger y = arc4random_uniform((u_int32_t)kWallHeight);
  NSInteger offset = WORLDOFFSETFROMXY(x, y);
  data[offset + 3] = 255;
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

      NSInteger redTotal = 0;
      NSInteger greenTotal = 0;
      NSInteger blueTotal = 0;
      for (NSInteger yn = iy - 1; yn <= iy + 1; ++yn) {
        for (NSInteger xn = ix - 1; xn <= ix + 1; ++xn) {
          NSInteger neighborOffset = WORLDOFFSETFROMXY(xn, yn);
          BOOL isNeighborAlive = ((_oldWorldBuffer[neighborOffset + 3] == 255) ? 1 : 0);
          if (isNeighborAlive) {
            ++numberOfNeighbors;
            redTotal += _oldWorldBuffer[neighborOffset + 0];
            greenTotal += _oldWorldBuffer[neighborOffset + 1];
            blueTotal += _oldWorldBuffer[neighborOffset + 2];
          }
        }
      }

      if (isAlive) {
        if (numberOfNeighbors < 2 || numberOfNeighbors >= 4) {
          // Any live cell with fewer than two live neighbours dies, as if caused by under-population.
          // Any live cell with more than three live neighbours dies, as if by overcrowding.
          data[offset + 3] = 0;
          didChange = YES;

        } // else any live cell with two or three live neighbours lives on to the next generation.

      } else if (numberOfNeighbors == 3) {
        // Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
        data[offset + 0] = MIN(255, redTotal / numberOfNeighbors);
        data[offset + 1] = MIN(255, greenTotal / numberOfNeighbors);
        data[offset + 2] = MIN(255, blueTotal / numberOfNeighbors);
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
  if (self.driver.hihatAmplitude > 0.5) {
    [self addRandomLife];
  }

  if (self.bassDegrader.value > 0.1 && [NSDate timeIntervalSinceReferenceDate] >= _lastTick + _deltaToNextTick * (1 - self.bassDegrader.value)) {
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

- (NSString *)tooltipName {
  return @"Conway's Game of Life";
}

@end
