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

#import "PHLinesAnimation.h"

static const NSTimeInterval kDeltaBetweenLineBirths = 0.3;

CGPoint startingPoints[] = {
  {-15, -15},
  {63, -15},
  {63, 47},
  {-15, 47},
};

@interface PHLine : NSObject
@property (nonatomic, assign) CGPoint pt1;
@property (nonatomic, assign) CGPoint dst1;
@property (nonatomic, assign) CGPoint pt2;
@property (nonatomic, assign) CGPoint dst2;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, strong) NSColor *color;
@property (nonatomic, assign) CGFloat alpha;
@property (nonatomic, assign) CGFloat age;
@property (nonatomic, assign) CGFloat pt1scale;
@property (nonatomic, assign) CGFloat pt2scale;
+ (PHLine *)generateLine;
@end

@implementation PHLine

+ (u_int32_t)indexNearIndex:(u_int32_t)index {
  return ((index + 4) + (arc4random_uniform(100) < 50 ? 1 : -1)) % 4;
}

+ (u_int32_t)oppositeIndexFromIndex:(u_int32_t)index {
  return (index + 4 + 2) % 4;
}

+ (PHLine *)generateLine {
  PHLine* line = [[PHLine alloc] init];

  u_int32_t index1 = arc4random_uniform(4);
  u_int32_t index2 = [self oppositeIndexFromIndex:index1];
  line.pt1 = startingPoints[index1];
  line.pt2 = startingPoints[index2];

  u_int32_t dstIndex1 = [self indexNearIndex:index1];
  u_int32_t dstIndex2 = [self indexNearIndex:index2];
  line.dst1 = startingPoints[dstIndex1];
  line.dst2 = startingPoints[dstIndex2];

  line.pt1scale = 1;
  line.pt2scale = 1;
  line.progress = ((CGFloat)arc4random_uniform(100) / 100.) * 0.5;
  line.pt1 = [line interpolatedPoint1];
  line.pt2 = [line interpolatedPoint2];
  line.progress = 0;

  line.pt1scale = ((CGFloat)arc4random_uniform(100) / 100.) * 0.5 + 1;
  line.pt2scale = ((CGFloat)arc4random_uniform(100) / 100.) * 0.5 + 1;

  line.alpha = ((CGFloat)arc4random_uniform(100) / 100.) * 0.5 + 0.5;
  return line;
}

- (CGPoint)interpolatedPoint1 {
  return CGPointMake((_dst1.x - _pt1.x) * _progress * _pt1scale + _pt1.x,
                     (_dst1.y - _pt1.y) * _progress * _pt1scale + _pt1.y);
}

- (CGPoint)interpolatedPoint2 {
  return CGPointMake((_dst2.x - _pt2.x) * _progress * _pt2scale + _pt2.x,
                     (_dst2.y - _pt2.y) * _progress * _pt2scale + _pt2.y);
}

@end

@implementation PHLinesAnimation {
  NSMutableArray* _lines;
  NSTimeInterval _nextLineBirthTime;
  CGFloat _colorAdvance;
}

- (id)init {
  if ((self = [super init])) {
    _lines = [NSMutableArray array];
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);
  CGFloat degraderValue = self.bassDegrader.value;
  _colorAdvance += self.secondsSinceLastTick * degraderValue;

  if ((!_nextLineBirthTime || [NSDate timeIntervalSinceReferenceDate] >= _nextLineBirthTime)
      && degraderValue > 0.2) {
    // Create a line.
    for (NSInteger ix = 0; ix < degraderValue * 4; ++ix) {
      PHLine* line = [PHLine generateLine];
      line.color = [NSColor colorWithDeviceHue:1 - fmodf(_colorAdvance, 1)
                                    saturation:self.vocalDegrader.value
                                    brightness:1
                                         alpha:1];
      [_lines addObject:line];
    }

    _nextLineBirthTime = [NSDate timeIntervalSinceReferenceDate] + kDeltaBetweenLineBirths;
  }

  CGContextSetBlendMode(cx, kCGBlendModeLighten);
  NSMutableArray *newLines = [NSMutableArray array];
  CGContextSetLineWidth(cx, self.vocalDegrader.value * 2 + 2);
  for (PHLine *line in _lines) {
    CGContextSaveGState(cx);
    CGMutablePathRef pathRef = CGPathCreateMutable();

    CGPoint pt1 = [line interpolatedPoint1];
    CGPoint pt2 = [line interpolatedPoint2];
    CGPathMoveToPoint(pathRef, NULL, pt1.x, pt1.y);
    CGPathAddLineToPoint(pathRef, NULL, pt2.x, pt2.y);

    CGContextAddPath(cx, pathRef);
    CGPathRelease(pathRef);

    CGContextSetStrokeColorWithColor(cx, line.color.CGColor);
    CGContextSetAlpha(cx, 1 - line.age / 3);
    CGContextStrokePath(cx);

    CGContextRestoreGState(cx);

    line.age += self.secondsSinceLastTick;
    line.progress += MAX(0.1 * self.secondsSinceLastTick, self.secondsSinceLastTick * degraderValue * 0.1);

    if (line.progress <= 1 && line.age < 3) {
      [newLines addObject:line];
    }
  }

  _lines = newLines;
  CGContextRestoreGState(cx);
}

- (NSImage *)previewImage {
  return [NSImage imageNamed:@"lines"];
}

- (NSString *)tooltipName {
  return @"Lines";
}

- (NSArray *)categories {
  return @[
           PHAnimationCategoryShapes
           ];
}

@end
