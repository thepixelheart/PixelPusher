//
//  PHCircleAnimation.m
//  PixelDriver
//
//  Created by Anton on 12/23/12.
//  Copyright (c) 2012 Pixel Heart. All rights reserved.
//

#import "PHFlyingRectAnimation.h"
#include <stdlib.h>
#import "Utilities.h"

static const CGFloat kEmitDistance = 100.0f;
static const CGFloat kBeginToFadeDistance = 80.0f;
static const CGFloat kDistanceStep = 1.0;
static const int kMaxRectanglesOnScreen = 20;
static const int kMaxRectanglesAddedPerStep = 5;

@interface PHRect : NSObject
@end

@implementation PHRect {
  CGRect _rect;
  CGFloat _distance;
  CGFloat _speed;
  NSColor* _color;
}

- (id)initWithRect:(CGRect) rect {
  if ((self = [super init])) {
    _rect = rect;
    _distance = 0;
    _speed = kDistanceStep;
    _color = generateRandomColor();
  }
  return self;
}

- (void)tickWithSpeedMultiplier:(CGFloat)speedMultiplier {
  _distance += speedMultiplier * _speed;
}

- (CGRect)computeDrawRect:(CGSize)size {
  return CGRectMake(size.width / 2 + _rect.origin.x * _distance,
                    size.height / 2 + _rect.origin.y * _distance,
                    _rect.size.width * _distance,
                    _rect.size.height * _distance);

}

- (void)renderInContext:(CGContextRef)cx size:(CGSize)size {
  // project the rect on the screen
  CGFloat alpha = ((_distance < kBeginToFadeDistance)
                   ? 1
                   : PHEaseInEaseOut(1 - ((_distance - kBeginToFadeDistance) / (kEmitDistance - kBeginToFadeDistance))));
  CGContextSetRGBFillColor(cx, [_color redComponent], [_color greenComponent], [_color blueComponent], [_color alphaComponent] * alpha);
  CGContextFillRect(cx, [self computeDrawRect:size]);
}

-(BOOL)isVisible:(CGSize)size {
  if (_distance > kEmitDistance) {
    return NO;
  }

  CGRect drawRect = [self computeDrawRect:size];
  CGRect screenRect = CGRectMake(0, 0, size.width, size.height);

  return CGRectIntersectsRect(drawRect, screenRect);
}

@end

@implementation PHFlyingRectAnimation {
    NSMutableArray *_rects;
}

- (id)init {
  if ((self = [super init])) {
    _rects = [[NSMutableArray alloc] init];
    self.bassDegrader.deltaPerSecond = 0.25;
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  if (self.driver.unifiedSpectrum) {
    // remove invisible rects
    NSMutableArray *invisibleRects = [NSMutableArray array];
    for(PHRect* rect in _rects) {
      if (![rect isVisible:size]) {
        [invisibleRects addObject:rect];
      }
    }
    [_rects removeObjectsInArray:invisibleRects];


    if (self.hihatDegrader.value > 0.2 && [_rects count] < kMaxRectanglesOnScreen) {
      for (int i = 0; i < kMaxRectanglesAddedPerStep * self.hihatDegrader.value; ++i) {
        PHRect* rect = [[PHRect alloc] initWithRect:CGRectMake(arc4random_uniform(size.width * 2) / size.width - 1,
                                                               arc4random_uniform(size.height * 2) / size.height - 1,
                                                               arc4random_uniform(size.width / 2) / size.width,
                                                               arc4random_uniform(size.height / 2) / size.height)];
        [_rects addObject:rect];
      }
    }

    // tick and render the rects;
    for(PHRect* rect in _rects) {
      [rect tickWithSpeedMultiplier: self.bassDegrader.value];
      //            [rect tickWithSpeedMultiplier: 1];
      [rect renderInContext:cx size:size];
    }
  }
}

- (NSString *)tooltipName {
  return @"Flying Rectangles";
}

@end
