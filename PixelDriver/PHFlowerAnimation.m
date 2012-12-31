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

#import "PHFlowerAnimation.h"

static const NSTimeInterval kMinimumRadianBeforeNewPetal = M_PI * 2 / 360 * 20;

@interface PHPetal : NSObject
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, assign) CGFloat radians;
@property (nonatomic, strong) NSColor* color;
@end

@implementation PHPetal
@end

@implementation PHFlowerAnimation {
  NSMutableArray* _petals;
}

- (id)init {
  if ((self = [super init])) {
    _petals = [NSMutableArray array];

    PHPetal* petal = [[PHPetal alloc] init];
    petal.color = generateRandomColor();
    petal.scale = 0.01;
    [_petals addObject:petal];
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);
  CGPoint centerPoint = CGPointMake(size.width / 2, size.height / 2);
  CGFloat centerRadius = self.vocalDegrader.value * 8;
  CGFloat maxPetalLength = size.width * 3 / 4;
  CGContextSetBlendMode(cx, kCGBlendModeColor);
  NSArray* petals = [_petals copy];
  for (PHPetal* petal in [petals reverseObjectEnumerator]) {
    CGFloat alpha = 1;
    if (petal.scale >= 0.9) {
      alpha = MAX(0, (1 - petal.scale) / 0.1);
    }
    CGContextSetRGBFillColor(cx, petal.color.redComponent, petal.color.greenComponent, petal.color.blueComponent, alpha);
    CGMutablePathRef pathRef = CGPathCreateMutable();

    CGFloat xNormal = cosf(petal.radians);
    CGFloat yNormal = sinf(petal.radians);
    CGFloat radialScale = MIN(1, petal.scale + 0.2);
    CGFloat xCurveNormal1 = cosf(petal.radians + M_PI * 2 / 360 * 20 * radialScale);
    CGFloat yCurveNormal1 = sinf(petal.radians + M_PI * 2 / 360 * 20 * radialScale);
    CGFloat xCurveNormal2 = cosf(petal.radians + M_PI * 2 / 360 * 80 * radialScale);
    CGFloat yCurveNormal2 = sinf(petal.radians + M_PI * 2 / 360 * 80 * radialScale);
    CGFloat xCurveNormal3 = cosf(petal.radians - M_PI * 2 / 360 * 80 * radialScale);
    CGFloat yCurveNormal3 = sinf(petal.radians - M_PI * 2 / 360 * 80 * radialScale);
    CGFloat xCurveNormal4 = cosf(petal.radians - M_PI * 2 / 360 * 20 * radialScale);
    CGFloat yCurveNormal4 = sinf(petal.radians - M_PI * 2 / 360 * 20 * radialScale);

    CGFloat startScale = petal.scale * 3 + 1;
    CGFloat endScale = petal.scale * 2 + 2;

    CGPoint petalStartPoint = CGPointMake(centerPoint.x + xNormal * centerRadius * startScale,
                                          centerPoint.y + yNormal * centerRadius * startScale);
    CGPathMoveToPoint(pathRef, nil, petalStartPoint.x, petalStartPoint.y);
    CGPathAddCurveToPoint(pathRef, nil,
                          centerPoint.x + xCurveNormal3 * centerRadius * startScale + xCurveNormal3 * petal.scale * 0.2 * maxPetalLength * startScale,
                          centerPoint.y + yCurveNormal3 * centerRadius * startScale + yCurveNormal3 * petal.scale * 0.2 * maxPetalLength * startScale,
                          centerPoint.x + xCurveNormal4 * centerRadius * startScale + xCurveNormal4 * petal.scale * 0.9 * maxPetalLength * endScale,
                          centerPoint.y + yCurveNormal4 * centerRadius * startScale + yCurveNormal4 * petal.scale * 0.9 * maxPetalLength * endScale,
                          petalStartPoint.x + xNormal * petal.scale * maxPetalLength * endScale,
                          petalStartPoint.y + yNormal * petal.scale * maxPetalLength * endScale);
    CGPathAddCurveToPoint(pathRef, nil,
                          centerPoint.x + xCurveNormal1 * centerRadius * startScale + xCurveNormal1 * petal.scale * 0.9 * maxPetalLength * endScale,
                          centerPoint.y + yCurveNormal1 * centerRadius * startScale + yCurveNormal1 * petal.scale * 0.9 * maxPetalLength * endScale,
                          centerPoint.x + xCurveNormal2 * centerRadius * startScale + xCurveNormal2 * petal.scale * 0.2 * maxPetalLength * startScale,
                          centerPoint.y + yCurveNormal2 * centerRadius * startScale + yCurveNormal2 * petal.scale * 0.2 * maxPetalLength * startScale,
                          petalStartPoint.x, petalStartPoint.y);

    CGPathCloseSubpath(pathRef);

    CGContextAddPath(cx, pathRef);
    CGContextFillPath(cx);

    petal.scale += self.secondsSinceLastTick / 12;
    petal.radians += self.secondsSinceLastTick * M_PI_2;

    if (alpha == 0) {
      [_petals removeObject:petal];
    }
  }

  PHPetal* lastPetal = [_petals lastObject];
  if (lastPetal.radians >= kMinimumRadianBeforeNewPetal) {
    PHPetal* petal = [[PHPetal alloc] init];
    petal.color = generateRandomColor();
    petal.scale = 0.01;
    [_petals addObject:petal];
  }
  CGContextRestoreGState(cx);
}

- (NSString *)tooltipName {
  return @"Flower";
}

@end
