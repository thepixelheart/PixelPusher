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

#import "PHRipplesAnimation.h"

@interface PHRipple : NSObject
@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, strong) NSColor* color;
@property (nonatomic, assign) CGPoint offset;
@end

@implementation PHRipple
@end

@implementation PHRipplesAnimation {
  NSMutableArray* _ripples; // PHRipple
  CGFloat _colorAdvance;
  CGFloat _movementAdvance;
  BOOL _stationary;
}

+ (id)animationStationary {
  PHRipplesAnimation* animation = [super animation];
  animation->_stationary = YES;
  return animation;
}

- (id)init {
  if ((self = [super init])) {
    _ripples = [NSMutableArray array];
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);

  _colorAdvance += self.secondsSinceLastTick / 16;
  _movementAdvance += self.secondsSinceLastTick / 8 * self.bassDegrader.value;

  PHRipple* newRipple = [[PHRipple alloc] init];
  CGFloat value;
  if (self.driver.unifiedWaveData) {
    value = fabsf(self.driver.unifiedWaveData[self.driver.numberOfWaveDataValues - 1]);
  } else {
    value = 0;
  }
  CGFloat scaledValue = value * 0.5 + 0.5;
  newRipple.color = [NSColor colorWithDeviceHue:1 - fmodf(_colorAdvance, 1)
                                     saturation:scaledValue
                                     brightness:scaledValue
                                          alpha:1];
  if (!_stationary) {
    CGPoint offset = CGPointMake(cos(_movementAdvance * 4 * 5) * 10, sin(_movementAdvance * 4 * 3) * 10);
    newRipple.offset = offset;
  }
  newRipple.radius = fabsf(value) * 10;
  [_ripples addObject:newRipple];

  CGFloat maxRadius = size.width - 10;
  NSArray* ripples = [_ripples copy];
  for (PHRipple* ripple in ripples) {
    CGContextSetStrokeColorWithColor(cx, ripple.color.CGColor);
    if (ripple.radius >= maxRadius - 5) {
      CGContextSetAlpha(cx, 1 - ripple.radius - (maxRadius - 5) / 5);
    } else {
      CGContextSetAlpha(cx, 1);
    }
    CGContextStrokeEllipseInRect(cx, CGRectInset(CGRectMake(ripple.offset.x + size.width / 2,
                                                            ripple.offset.y + size.height / 2, 0, 0),
                                                 -ripple.radius,
                                                 -ripple.radius));
    ripple.radius += 0.5 * MAX(0.1, PHEaseOut(1 - (ripple.radius / maxRadius)));

    if (ripple.radius >= maxRadius) {
      [_ripples removeObject:ripple];
    }
  }
  CGContextRestoreGState(cx);
}

- (NSString *)tooltipName {
  return _stationary ? @"Stationary Ripples" : @"Ripples";
}

@end
