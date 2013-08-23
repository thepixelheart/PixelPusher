//
// Copyright 2012-2013 David Shimel
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

#import "PHRaindropRipplesAnimation.h"

static const NSTimeInterval kMinimumDropInterval = 0.5;
static const NSTimeInterval kMaximumDropInterval = 1.0;
static const NSTimeInterval _durationMin = 1;
static const NSTimeInterval _durationMax = 2;

@interface PHRaindropWithRipples : NSObject
@property (nonatomic, assign) CGPoint pos;
@property (nonatomic, assign) NSTimeInterval initialLife;
@property (nonatomic, assign) NSTimeInterval life;
@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, assign) CGFloat hue;
@end

@implementation PHRaindropWithRipples
@end

@implementation PHRaindropRipplesAnimation {
  NSMutableArray* _raindrops;
  NSTimeInterval _nextDropInterval;
}

- (id)init {
  if ((self = [super init])) {
    _raindrops = [NSMutableArray array];
  }
  return self;
}

- (void)createDrop {
  PHRaindropWithRipples* drop = [[PHRaindropWithRipples alloc] init];
  drop.pos = CGPointMake(arc4random_uniform(kWallWidth), arc4random_uniform(kWallHeight));
  drop.initialLife = _durationMin + farc4random_uniform(_durationMax - _durationMin, 1000);
  drop.life = drop.initialLife;
  drop.hue = ((CGFloat)arc4random_uniform(256)) / 256.;
  _nextDropInterval = kMinimumDropInterval + farc4random_uniform(kMaximumDropInterval - kMinimumDropInterval, 1000);
  [_raindrops addObject:drop];
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);

  _nextDropInterval -= self.secondsSinceLastTick;
  if(_nextDropInterval <= 0) {
    [self createDrop];
	}
  
	for (PHRaindropWithRipples* drop in [_raindrops copy]) {
    drop.life -= self.secondsSinceLastTick;
    drop.radius += self.secondsSinceLastTick * kWallWidth / 2;
    
    BOOL shouldDrawDrop = drop.life > 0;
    BOOL shouldDrawRipple = drop.radius < kWallWidth * 1.5;

    if (!shouldDrawDrop && !shouldDrawRipple) {
      [_raindrops removeObject:drop];
      continue;
    }
    if (shouldDrawDrop) {
      CGFloat perc = drop.life / drop.initialLife;
      CGContextSetFillColorWithColor(cx, [NSColor colorWithDeviceHue:drop.hue saturation:1 brightness:1 alpha:perc].CGColor);
      CGContextFillRect(cx, CGRectMake(drop.pos.x, drop.pos.y, 1, 1));
    }
    if (shouldDrawRipple) {
      CGContextSetStrokeColorWithColor(cx, [NSColor colorWithDeviceHue:fast_fmod(drop.hue + drop.radius / (kWallWidth * 2), 1) saturation:1 brightness:1 alpha:1].CGColor);
      CGContextStrokeEllipseInRect(cx, CGRectMake(drop.pos.x - drop.radius + 0.5, drop.pos.y - drop.radius + 0.5, drop.radius * 2, drop.radius * 2));
    }
	}
  
  CGContextRestoreGState(cx);
}

- (NSImage *)previewImage {
  return [NSImage imageNamed:@"rainsplash"];
}

- (NSString *)tooltipName {
  return @"Raindrop Ripples";
}

- (NSArray *)categories {
  return @[
    PHAnimationCategoryShapes
  ];
}

@end
