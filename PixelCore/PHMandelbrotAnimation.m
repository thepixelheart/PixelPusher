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

#import <complex.h>

static const NSTimeInterval kBounceDuration = 30;
static const double kZoomMin = 0.7;
static const double kZoomMax = 0.00001;

static const CGPoint kInterestingZoomPoints[] = {
  {0.85001, .7005},
  {0.36, 1.0075},
  {-1.249, 0.00999},
  {-.40395, -0.24905},
  {-.215, 0.25},
  {-1, 0},
};

@implementation PHMandelbrotAnimation {
  CGContextRef _bitmapContextRef;
  CGPoint _centerOffset;
  CGPoint _nextCenterOffset;
  double _zoom;
  NSTimeInterval _accum;
}

- (void)dealloc {
  if (_bitmapContextRef) {
    CGContextRelease(_bitmapContextRef);
  }
}

- (CGPoint)randomPoint {
  CGPoint point = kInterestingZoomPoints[arc4random_uniform(sizeof(kInterestingZoomPoints) / sizeof(kInterestingZoomPoints[0]))];
  if (arc4random_uniform(1000) < 500) {
    point.y = -point.y;
  }
  return point;
}

- (id)init {
  if ((self = [super init])) {
    _bitmapContextRef = PHCreate8BitBitmapContextWithSize(CGSizeMake(kWallWidth, kWallHeight));
    _zoom = 1;
    _nextCenterOffset = [self randomPoint];
    _centerOffset = _nextCenterOffset;
  }
  return self;
}

- (void)renderFrameAtOffset:(CGPoint)offset {
  unsigned char* data = (unsigned char *)CGBitmapContextGetData(_bitmapContextRef);
  size_t bytesPerRow = CGBitmapContextGetBytesPerRow(_bitmapContextRef);

  static const double kMandelWidth = 3;
  static const double kMandelHeight = 3;
  static const double kMandelCenterX = -0.5;
  static const double kMandelCenterY = 0;

  double width = kMandelWidth * _zoom;
  double height = kMandelHeight * _zoom;
  double x = kMandelCenterX + offset.x + cosf(_accum * .5) * 0.00001;
  double y = kMandelCenterY + offset.y + sinf(_accum * 1.3) * 0.00001;

  double xa = x - width / 2;
  double xb = x + width / 2;
  double ya = y - height / 2;
  double yb = y + height / 2;

  static const int kMaxNumberOfIterations = 128;
  static const double kMandelbrotWidth = 48;
  static const double kMandelbrotHeight = 32;

  for (NSInteger iy = 0; iy < kWallHeight; ++iy) {
    double y = (double)iy / (double)kWallHeight * kMandelbrotHeight;
    double cy = y * (yb - ya) / ((double)kWallHeight - 1) + ya;
    for (NSInteger ix = 0; ix < kWallWidth; ++ix) {
      double x = (double)ix / (double)kWallWidth * kMandelbrotWidth;
      double cx = x * (xb - xa) / ((double)kWallWidth - 1) + xa;
      double _Complex c = cx + cy * I;
      double _Complex z = 0;

      NSInteger i;
      for (i = 0; i < kMaxNumberOfIterations; ++i) {
        if (cabs(z) > 2.0) {
          break;
        }
        z = z * z + c;
      }

      double colorScale = ((double)i / (double)kMaxNumberOfIterations);

      NSInteger offset = ix * 4 + iy * bytesPerRow;
/*
      NSColor* color = [NSColor colorWithDeviceHue:colorScale
                                        saturation:1
                                        brightness:1
                                             alpha:1];
      CGFloat r,g,b,a;
      [color getRed:&r green:&g blue:&b alpha:&a];
      data[offset + 0] = r * 255;
      data[offset + 1] = g * 255;
      data[offset + 2] = b * 255;
      data[offset + 3] = 255;*/

      double perc = sinf(fmodf(_accum, kBounceDuration) / kBounceDuration * M_PI * 2) * 0.5 + 0.5;
      double perc2 = sinf(_accum) * 0.5 + 0.5;
      data[offset + 0] = sqrtf(colorScale) * 255 * perc;
      data[offset + 1] = sqrtf(colorScale) * 255 * (1 - perc);
      data[offset + 2] = sqrtf(colorScale) * 255 * perc2;
      data[offset + 3] = 255;
    }
  }
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  _accum += self.secondsSinceLastTick;

  double perc = fmodf(_accum, kBounceDuration) / kBounceDuration;
  // 0.5 is fully-zoomed, 1 is back at the origin

  if (perc < 0.2) {
    double interp = PHEaseOut(perc / 0.2) * 0.5 + 0.5;
    CGPoint interpolated = CGPointMake((_nextCenterOffset.x - _centerOffset.x) * interp + _centerOffset.x,
                                       (_nextCenterOffset.y - _centerOffset.y) * interp + _centerOffset.y);
    [self renderFrameAtOffset:interpolated];

  } else if (perc < 0.8) {
    _centerOffset = _nextCenterOffset;
    [self renderFrameAtOffset:_centerOffset];

  } else {
    if (CGPointEqualToPoint(_centerOffset, _nextCenterOffset)) {
      _nextCenterOffset = [self randomPoint];
    }
    double interp = PHEaseIn((perc - 0.8) / 0.2) * 0.5;
    CGPoint interpolated = CGPointMake((_nextCenterOffset.x - _centerOffset.x) * interp + _centerOffset.x,
                                       (_nextCenterOffset.y - _centerOffset.y) * interp + _centerOffset.y);
    [self renderFrameAtOffset:interpolated];
  }

  double oscillation = 1 - powf(cosf(perc * M_PI), 6);

  _zoom = (kZoomMax - kZoomMin) * oscillation + kZoomMin;

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
