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

#import "PHFlippingSquaresAnimation.h"

@implementation PHFlippingSquaresAnimation {
  CGFloat _advance;
  CGFloat _bassAdvance;
  CGFloat _hihatAdvance;
  CGFloat _vocalAdvance;
  CGFloat _snareAdvance;
  
  NSInteger _randomTiles[1000];
}

- (id)init {
  if ((self = [super init])) {
    _bassAdvance = arc4random_uniform(1000);
    _hihatAdvance = arc4random_uniform(1000);
    _vocalAdvance = arc4random_uniform(1000);
    _snareAdvance = arc4random_uniform(1000);
    
    self.bassDegrader.deltaPerSecond = 0.5;
    
    for (NSInteger ix = 0; ix < 1000; ++ix) {
      _randomTiles[ix] = arc4random_uniform(4);
    }
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);
  
  if (self.animationTick.hardwareState.didTapUserButton1
      || self.animationTick.hardwareState.didTapUserButton2) {
    for (NSInteger ix = 0; ix < 1000; ++ix) {
      _randomTiles[ix] = arc4random_uniform(4);
    }
  }

  _advance += self.secondsSinceLastTick;
  
  _bassAdvance += self.bassDegrader.value * self.secondsSinceLastTick * 10;
  _hihatAdvance += self.hihatDegrader.value * self.secondsSinceLastTick * 10;
  _vocalAdvance += self.vocalDegrader.value * self.secondsSinceLastTick * 10;
  _snareAdvance += self.snareDegrader.value * self.secondsSinceLastTick * 10;
  
  CGFloat advances[4] = {
    _bassAdvance,
    _hihatAdvance,
    _vocalAdvance,
    _snareAdvance
  };
  
  NSColor* colors[4] = {
    [NSColor colorWithDeviceHue:cos(_bassAdvance * 0.03) * 0.5 + 0.5 saturation:1 brightness:1 alpha:1],
    [NSColor colorWithDeviceHue:cos(_hihatAdvance * 0.015) * 0.5 + 0.5 saturation:1 brightness:1 alpha:1],
    [NSColor colorWithDeviceHue:cos(_vocalAdvance * 0.02) * 0.5 + 0.5 saturation:1 brightness:1 alpha:1],
    [NSColor colorWithDeviceHue:cos(_snareAdvance * 0.023) * 0.5 + 0.5 saturation:1 brightness:1 alpha:1],
  };
  
  CGContextSetBlendMode(cx, kCGBlendModeLighten);

  CGFloat squareSize = size.height / 6;

  for (CGFloat y = 0; y < size.height / (squareSize * 2); ++y) {
    for (CGFloat x = 0; x < size.width / (squareSize * 2); ++x) {
      CGContextSaveGState(cx);
      
      NSInteger whichAdvance = _randomTiles[(NSInteger)(x + y * 100)];
      CGFloat advance = advances[whichAdvance];
      
      CGFloat scale = sin(advance);
      CGFloat scale2 = cos(advance);

      CGContextSetFillColorWithColor(cx, colors[whichAdvance].CGColor);

      CGContextTranslateCTM(cx, x * squareSize * 2 + squareSize, y * squareSize * 2 + squareSize);
      CGContextMoveToPoint(cx, -squareSize - scale2 * (squareSize / 5), -squareSize * scale);
      CGContextAddLineToPoint(cx, squareSize + scale2 * (squareSize / 5), -squareSize * scale);
      CGContextAddLineToPoint(cx, squareSize - scale2 * (squareSize / 5), squareSize * scale);
      CGContextAddLineToPoint(cx, -squareSize + scale2 * (squareSize / 5), squareSize * scale);
      CGContextClosePath(cx);
      CGContextFillPath(cx);

      CGContextRestoreGState(cx);
    }
  }


  CGContextRestoreGState(cx);
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  [self renderBitmapInContext:cx size:size];
}

- (NSString *)tooltipName {
  return @"Flipping Squares";
}

- (NSArray *)categories {
  return @[
           PHAnimationCategoryShapes
           ];
}

@end
