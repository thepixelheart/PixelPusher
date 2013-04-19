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
//

#import "PHPixelLifeAnimation.h"

typedef enum {
  PHPixelLifeGrow,
  PHPixelLifeBounce,
  PHPixelLifeRotate,
} PHPixelLife;

@interface PHPixel : NSObject
@property (nonatomic, assign) NSInteger ix;
@property (nonatomic, strong) NSColor* color;
@property (nonatomic, assign) CGPoint position;
@property (nonatomic, assign) CGPoint velocity;
@property (nonatomic, assign) CGFloat entropy;
@property (nonatomic, assign) NSInteger whichInstrument;
@property (nonatomic, assign) PHPixelLife life;
@end

@implementation PHPixel
@end

@implementation PHPixelLifeAnimation {
  NSArray *_pixels;
  NSInteger _offset;
}

- (id)init {
  if ((self = [super init])) {
    NSMutableArray *pixels = [NSMutableArray array];
    for (NSInteger ix = 0; ix < kWallWidth * kWallHeight; ++ix) {
      PHPixel* pixel = [[PHPixel alloc] init];
      pixel.ix = ix;

      CGFloat perc = (CGFloat)ix / (CGFloat)(kWallWidth * kWallHeight) * 0.4;
      pixel.color = [NSColor colorWithDeviceHue:perc saturation:1 brightness:1 alpha:1];
      pixel.position = CGPointMake(ix % kWallWidth, ix / kWallWidth);

      pixel.life = arc4random_uniform(3);
      pixel.whichInstrument = arc4random_uniform(4);
      pixel.entropy = ((CGFloat)arc4random_uniform(10000) / 10000.) * 1.8 + 0.2;

      [pixels addObject:pixel];
    }
    _pixels = pixels;
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);

  CGContextSetAllowsAntialiasing(cx, NO);
  CGContextSetBlendMode(cx, kCGBlendModeColor);

  _offset += self.animationTick.hardwareState.numberOfRotationTicks * 10;
  CGFloat max = (CGFloat)(kWallWidth * kWallHeight);
  _offset = fmod(_offset + max, max);

  NSArray *instrumentValues = @[@(self.bassDegrader.value),
                                @(self.hihatDegrader.value),
                                @(self.vocalDegrader.value),
                                @(self.snareDegrader.value)];
  for (PHPixel* pixel in _pixels) {
    CGContextSaveGState(cx);

    CGFloat perc = fmodf((CGFloat)pixel.ix / max * 0.4 + _offset / max, 1);
    pixel.color = [NSColor colorWithDeviceHue:perc saturation:1 brightness:1 alpha:1];

    CGContextTranslateCTM(cx, pixel.position.x + 0.5, pixel.position.y + 0.5);
    CGFloat instrumentValue = [instrumentValues[pixel.whichInstrument] floatValue];

    if (pixel.life == PHPixelLifeGrow) {
      CGContextRotateCTM(cx, instrumentValue * M_PI);
    }
    if (pixel.life == PHPixelLifeBounce) {
      CGContextTranslateCTM(cx, 0, -instrumentValue * 2 * pixel.entropy);
    }

    CGFloat scale = 4;
    if (pixel.life == PHPixelLifeGrow) {
      CGContextScaleCTM(cx, instrumentValue * scale * pixel.entropy + 1, instrumentValue * scale * pixel.entropy + 1);
    }

    CGFloat velocityScale = 10;
    CGPoint velocity = pixel.velocity;
    velocity.x += self.bassDegrader.value * self.secondsSinceLastTick * velocityScale * pixel.entropy;
    velocity.x -= self.vocalDegrader.value * self.secondsSinceLastTick * velocityScale * pixel.entropy;
    velocity.y += self.hihatDegrader.value * self.secondsSinceLastTick * velocityScale * pixel.entropy;
    velocity.y -= self.snareDegrader.value * self.secondsSinceLastTick * velocityScale * pixel.entropy;
    pixel.velocity = velocity;

    CGContextSetFillColorWithColor(cx, pixel.color.CGColor);
    CGContextFillRect(cx, CGRectMake(-0.5, -0.5, 1, 1));

    CGPoint point = pixel.position;
    point.x += pixel.velocity.x * self.secondsSinceLastTick;
    point.y += pixel.velocity.y * self.secondsSinceLastTick;
    if (point.x < -1) {
      point.x += kWallWidth;
    } else if (point.x >= kWallWidth) {
      point.x -= kWallWidth;
    }
    if (point.y < -1) {
      point.y += kWallHeight;
    } else if (point.y >= kWallHeight) {
      point.y -= kWallHeight;
    }
    pixel.position = point;

    point = pixel.velocity;
    CGFloat speed = sqrt(point.x * point.x + point.y * point.y);
    if (speed > 0.0001) {
      CGPoint normal = CGPointMake(point.x / speed, point.y / speed);
      if (speed > 5) {
        point = CGPointMake(normal.x * 5, normal.y * 5);
        speed = 5;
      }
      CGPoint oppositeDirection = CGPointMake(-normal.x, -normal.y);
      CGFloat decreaseAmt = MIN(speed, self.secondsSinceLastTick * 5);
      point.x += oppositeDirection.x * decreaseAmt;
      point.y += oppositeDirection.y * decreaseAmt;
      pixel.velocity = point;

    } else {
      pixel.velocity = CGPointZero;
    }

    CGContextRestoreGState(cx);
  }

  CGContextRestoreGState(cx);
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  [self renderBitmapInContext:cx size:size];
}

- (NSString *)tooltipName {
  return @"Pixel Life";
}

@end
