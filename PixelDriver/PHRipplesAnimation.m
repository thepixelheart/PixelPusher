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
@end

@implementation PHRipple
@end

@implementation PHRipplesAnimation {
  NSMutableArray* _ripples; // PHRipple
  CGFloat _colorAdvance;
}

- (id)init {
  if ((self = [super init])) {
    _ripples = [NSMutableArray array];
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  if (self.driver.unifiedSpectrum) {
    CGContextSaveGState(cx);

    _colorAdvance += self.secondsSinceLastTick / 16;

    PHRipple* newRipple = [[PHRipple alloc] init];
    CGFloat value = fabsf(self.driver.unifiedWaveData[self.driver.numberOfWaveDataValues - 1]);
    CGFloat scaledValue = value * 0.5 + 0.5;
    newRipple.color = [NSColor colorWithDeviceHue:fmodf(_colorAdvance, 1)
                                       saturation:scaledValue
                                       brightness:scaledValue
                                            alpha:1];
    [_ripples addObject:newRipple];

    CGFloat maxRadius = size.width - 20;
    NSArray* ripples = [_ripples copy];
    for (PHRipple* ripple in ripples) {
      CGContextSetStrokeColorWithColor(cx, ripple.color.CGColor);
      CGContextSetAlpha(cx, 0.9);
      CGContextStrokeEllipseInRect(cx, CGRectInset(CGRectMake(size.width / 2, size.height / 2, 0, 0),
                                                   -ripple.radius,
                                                   -ripple.radius));
      ripple.radius += 0.5 * MAX(0.1, PHEaseInEaseOut(1 - (ripple.radius / maxRadius)));

      if (ripple.radius >= maxRadius) {
        [_ripples removeObject:ripple];
      }
    }
    CGContextRestoreGState(cx);
  }
}

- (NSString *)tooltipName {
  return @"Ripples";
}

@end
