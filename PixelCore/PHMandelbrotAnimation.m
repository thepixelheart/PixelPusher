//
// Copyright 2012-2013 Jeff Verkoeyen
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

#import "PHMandelbrotAnimation.h"

@implementation PHMandelbrotAnimation {
  CGContextRef _bitmapContextRef;
}

- (void)dealloc {
  if (_bitmapContextRef) {
    CGContextRelease(_bitmapContextRef);
  }
}

- (id)init {
  if ((self = [super init])) {
    _bitmapContextRef = PHCreate8BitBitmapContextWithSize(CGSizeMake(kWallWidth, kWallHeight));
  }
  return self;
}

- (void)renderFrame {
  unsigned char* data = (unsigned char *)CGBitmapContextGetData(_bitmapContextRef);
  size_t bytesPerRow = CGBitmapContextGetBytesPerRow(_bitmapContextRef);

  for (NSInteger iy = 0; iy < kWallHeight; ++iy) {
    for (NSInteger ix = 0; ix < kWallWidth; ++ix) {
      NSInteger offset = ix * 4 + iy * bytesPerRow;
      unsigned char value = arc4random_uniform(256);
      data[offset + 0] = value;
      data[offset + 1] = value;
      data[offset + 2] = value;
      data[offset + 3] = 255;
    }
  }
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  [self renderFrame];

  CGImageRef imageRef = CGBitmapContextCreateImage(_bitmapContextRef);
  CGContextDrawImage(cx, CGRectMake(0, 0, size.width, size.height), imageRef);
  CGImageRelease(imageRef);
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  [self renderBitmapInContext:cx size:size];
}

- (NSString *)tooltipName {
  return @"Mandelbrot";
}

@end
