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

double fast_fmod(double value, int modulo) {
  double remainder = value - floor(value);
  return (double)((int)value % modulo) + remainder;
}

void HSVtoRGB(CGFloat h, CGFloat s, CGFloat v, CGFloat* r, CGFloat* g, CGFloat* b) {
  double c = 0.0, m = 0.0, x = 0.0;
  h = fast_fmod(h, 360);
  c = v * s;
  x = c * (1.0 - fabs(fast_fmod(h / 60.0, 2) - 1.0));
  m = v - c;
  if (h >= 0.0 && h < 60.0) {
    *r = c + m;
    *g = x + m;
    *b = m;
  } else if (h >= 60.0 && h < 120.0) {
    *r = x + m;
    *g = c + m;
    *b = m;
  } else if (h >= 120.0 && h < 180.0) {
    *r = m;
    *g = c + m;
    *b = x + m;
  } else if (h >= 180.0 && h < 240.0) {
    *r = m;
    *g = x + m;
    *b = c + m;
  } else if (h >= 240.0 && h < 300.0) {
    *r = x + m;
    *g = m;
    *b = c + m;
  } else if (h >= 300.0 && h < 360.0) {
    *r = c + m;
    *g = m;
    *b = x + m;
  } else {
    *r = m;
    *g = m;
    *b = m;
  }
}

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
  double _colorAccum;
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

  static const int kMaxNumberOfIterations = 256;
  static const double kMandelbrotWidth = 48;
  static const double kMandelbrotHeight = 32;

  for (double iy = 0; iy < kWallHeight; ++iy) {
    for (double ix = 0; ix < kWallWidth; ++ix) {

      double rt = 0, gt = 0, bt = 0;
      for (double xo = -0.5; xo <= 0.5; xo += 0.5) {
        for (double yo = -0.5; yo <= 0.5; yo += 0.5) {
          double y = (double)(iy + yo) / (double)kWallHeight * kMandelbrotHeight;
          double cy = y * (yb - ya) / ((double)kWallHeight - 1) + ya;
          double x = (double)(ix + xo) / (double)kWallWidth * kMandelbrotWidth;
          double cx = x * (xb - xa) / ((double)kWallWidth - 1) + xa;

          double _Complex c = cx + cy * I;
          double _Complex z = 0;

          NSInteger i;
          for (i = 0; i < kMaxNumberOfIterations; ++i) {
            double imag = cimag(z);
            double real = creal(z);
            if (imag * imag + real * real > 4.0) {
              break;
            }
            z = z * z + c;
          }

          double colorScale = ((double)i / (double)kMaxNumberOfIterations);

          CGFloat r,g,b;
          HSVtoRGB((colorScale + 0.4 + _colorAccum) * 360, 1, i < kMaxNumberOfIterations ? 1 : 0.3, &r, &g, &b);

          rt += r * 1 / 9;
          gt += g * 1 / 9;
          bt += b * 1 / 9;
        }
      }

      NSInteger offset = ix * 4 + iy * bytesPerRow;

      data[offset + 0] = MAX(0, MIN(255, rt * 255));
      data[offset + 1] = MAX(0, MIN(255, gt * 255));
      data[offset + 2] = MAX(0, MIN(255, bt * 255));
      data[offset + 3] = 255;
      /*
       double perc = sinf(fmodf(_accum, kBounceDuration) / kBounceDuration * M_PI * 2) * 0.5 + 0.5;
       double perc2 = sinf(_accum) * 0.5 + 0.5;
       data[offset + 0] = sqrtf(colorScale) * 255 * perc;
       data[offset + 1] = sqrtf(colorScale) * 255 * (1 - perc);
       data[offset + 2] = sqrtf(colorScale) * 255 * perc2;
       data[offset + 3] = 255;*/
    }
  }
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  _accum += self.secondsSinceLastTick * (self.bassDegrader.value * 5 + 1);
  _colorAccum += self.secondsSinceLastTick * self.hihatDegrader.value * 0.8;

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
