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

#import "PHRotatingSquaresAnimation.h"

@interface PHSquare : NSObject
@property (nonatomic, assign) CGPoint center;
@property (nonatomic, assign) CGFloat centerOffset;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGFloat rotation;
@property (nonatomic, assign) CGFloat rotationDirection;
@end

@implementation PHSquare
@end

@implementation PHRotatingSquaresAnimation {
  NSArray *_squares;
  CGFloat _colorAdvance;
}

- (id)init {
  if ((self = [super init])) {
    NSMutableArray *squares = [NSMutableArray array];
    for (NSInteger ix = 0; ix < 4; ++ix) {
      NSInteger col = ix % 2;
      NSInteger row = ix / 2;
      PHSquare* square = [[PHSquare alloc] init];
      square.center = CGPointMake(col * kWallWidth / 2 + kWallWidth / 4,
                                  row * kWallHeight / 2 + kWallHeight / 4);
      square.size = CGSizeMake(kWallWidth / 8, kWallWidth / 8);
      [squares addObject:square];
    }
    _squares = squares;
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);

  _colorAdvance += self.secondsSinceLastTick * 0.3;

  NSArray* scales = @[@(self.bassDegrader.value),
                      @(self.hihatDegrader.value),
                      @(self.vocalDegrader.value),
                      @(self.snareDegrader.value),];

  CGContextSetBlendMode(cx, kCGBlendModeColor);

  CGFloat colorOffset = _colorAdvance;
  for (NSInteger ix = 0; ix < _squares.count; ++ix) {
    PHSquare* square = _squares[ix];

    CGContextSaveGState(cx);

    CGFloat offset = colorOffset;
    CGFloat red = sin(offset) * 0.5 + 0.5;
    CGFloat green = cos(offset * 5 + M_PI_2) * 0.5 + 0.5;
    CGFloat blue = sin(offset * 13 - M_PI_4) * 0.5 + 0.5;

    CGContextSetFillColorWithColor(cx, [NSColor colorWithDeviceRed:red green:green blue:blue alpha:1].CGColor);

    CGFloat scale = [scales[ix] floatValue];
    
    CGContextTranslateCTM(cx,
                          square.center.x + cos(square.centerOffset * 3 * (ix + 1)) * 10,
                          square.center.y + sin(square.centerOffset * 7 * (ix + 1)) * 5);
    CGContextRotateCTM(cx, square.rotation);
    CGContextScaleCTM(cx, scale * 4 + 1, scale * 4 + 1);

    CGContextFillRect(cx, CGRectMake(-square.size.width / 2, -square.size.height / 2, square.size.width, square.size.height));

    CGContextRestoreGState(cx);

    colorOffset += 0.1;
    square.centerOffset += scale * self.secondsSinceLastTick * 0.5;
    square.rotationDirection += scale * self.secondsSinceLastTick;
    square.rotation += scale * self.secondsSinceLastTick * 6 * sin(square.rotationDirection);
  }

  CGContextRestoreGState(cx);
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  [self renderBitmapInContext:cx size:size];
}

- (NSString *)tooltipName {
  return @"Rotating Squares";
}

- (NSArray *)categories {
  return @[
           PHAnimationCategoryShapes
           ];
}

@end
