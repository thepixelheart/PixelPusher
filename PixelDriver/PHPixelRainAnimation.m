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

#import "PHPixelRainAnimation.h"

static const NSInteger kMaxNumberOfRainDropsToCreatePerFrame = 10;
static const NSTimeInterval kMinimumTimeBetweenDetectingPeak = 0.05;
static const NSTimeInterval kMinimumTimeBeforeCreatingRaindrops = 0.4;
static const CGFloat kMinimumRaindropLength = 2;
static const CGFloat kMaximumRaindropLength = 4;

@interface PHRaindrop : NSObject
@property (nonatomic, assign) CGPoint pos;
@property (nonatomic, assign) CGPoint vel;
@property (nonatomic, assign) CGFloat length;
@property (nonatomic, strong) NSColor* color;
@end

@implementation PHRaindrop
@end

@implementation PHPixelRainAnimation {
  NSMutableArray* _rainDrops;
  NSTimeInterval _lastTimeRaindropsCreated;
  NSTimeInterval _nextPeakDetectionTime;
  /*CGFloat _explosionAdvance;
  CGFloat _previousExplosionRadius;*/
}

- (id)init {
  if ((self = [super init])) {
    self.hihatDegrader.deltaPerSecond = 0.5; // About 2 seconds before the colors fade to gray.
    _rainDrops = [NSMutableArray array];
    _nextPeakDetectionTime = [NSDate timeIntervalSinceReferenceDate] + kMinimumTimeBetweenDetectingPeak;
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);

  NSInteger numberOfRainDropsToCrate = 0;
  if ([NSDate timeIntervalSinceReferenceDate] >= _nextPeakDetectionTime) {
    numberOfRainDropsToCrate = kMaxNumberOfRainDropsToCreatePerFrame * self.hihatDegrader.value;
    _nextPeakDetectionTime = [NSDate timeIntervalSinceReferenceDate] + kMinimumTimeBetweenDetectingPeak;
  }
  if (numberOfRainDropsToCrate == 0 && [NSDate timeIntervalSinceReferenceDate] - _lastTimeRaindropsCreated >= kMinimumTimeBeforeCreatingRaindrops) {
    numberOfRainDropsToCrate = arc4random_uniform(kMaxNumberOfRainDropsToCreatePerFrame - 1) + 1;
  }
  for (NSInteger ix = 0; ix < numberOfRainDropsToCrate; ++ix) {
    PHRaindrop* raindrop = [[PHRaindrop alloc] init];
    raindrop.pos = CGPointMake(arc4random_uniform(size.width - 1), -8);
    raindrop.length = arc4random_uniform(kMaximumRaindropLength - kMinimumRaindropLength) + kMinimumRaindropLength;
    raindrop.vel = CGPointMake(0, size.height + arc4random_uniform(30) - 10);
    raindrop.color = [generateRandomColor() colorWithAlphaComponent:0.5];
    [_rainDrops addObject:raindrop];
    _lastTimeRaindropsCreated = [NSDate timeIntervalSinceReferenceDate];
  }

  /*
   // Not a fan of this explosion code. Supposed to push particles out of the way of a moving circle
   // that expands to the bass.
  _explosionAdvance += self.secondsSinceLastTick / 8;
  CGFloat maxExplosionRadius = MIN(size.width, size.height) / 2;
  CGFloat explosionRadius = self.bassDegrader.value * maxExplosionRadius;
  CGPoint explosionCenter = CGPointMake(size.width / 2 + cosf(_explosionAdvance * 3) * (size.width / 3),
                                        size.height / 2 + sinf(_explosionAdvance * 5) * (size.height / 4));
  CGRect explosionFrame = CGRectMake(explosionCenter.x - explosionRadius, explosionCenter.y - explosionRadius, explosionRadius * 2, explosionRadius * 2);
  CGContextSetFil
  CGContextFillEllipseInRect(cx, explosionFrame);

  if (explosionRadius > _previousExplosionRadius) {
    CGFloat growth = explosionRadius - _previousExplosionRadius;
    CGFloat radiusSquared = explosionRadius * explosionRadius;

    NSArray* liveRaindrops = [_rainDrops copy];
    for (PHRaindrop* raindrop in liveRaindrops) {
      CGFloat xDelta = (raindrop.pos.x - explosionCenter.x);
      CGFloat yDelta = ((raindrop.pos.y - raindrop.length / 2) - explosionCenter.y);
      CGFloat distanceSquared = xDelta * xDelta + yDelta * yDelta;
      if (distanceSquared == 0) {
        [_rainDrops removeObject:raindrop];
        continue;
      }

      if (distanceSquared <= radiusSquared) {
        // Line's within the bounds of the explosion.
        CGFloat distance = sqrt(distanceSquared);

        CGFloat xNormal = xDelta / distance;
        CGFloat yNormal = yDelta / distance;
        CGFloat energy = growth + 1 - distance / maxExplosionRadius;
        CGPoint vel = raindrop.vel;
        vel.x += xNormal * energy;
        vel.y += yNormal * energy;
        raindrop.vel = vel;
      }
    }
  }*/

  NSColor* grayColor = [[NSColor grayColor] colorWithAlphaComponent:0.5];
  NSArray* liveRaindrops = [_rainDrops copy];
  for (PHRaindrop* raindrop in liveRaindrops) {
    if (raindrop.pos.y - raindrop.length >= size.height + 8) {
      [_rainDrops removeObject:raindrop];
      continue;
    }

    NSColor* color = [raindrop.color blendedColorWithFraction:1 - self.vocalDegrader.value ofColor:grayColor];
    CGContextSetFillColorWithColor(cx, color.CGColor);
    CGRect frame = CGRectMake(raindrop.pos.x, raindrop.pos.y - raindrop.length, 1, raindrop.length);
    CGContextFillRect(cx, frame);

    CGPoint pos = raindrop.pos;
    pos.y += self.secondsSinceLastTick * raindrop.vel.y;
    pos.x += self.secondsSinceLastTick * raindrop.vel.x;
    raindrop.pos = pos;

    CGPoint vel = raindrop.vel;
    vel.y += self.secondsSinceLastTick * 9.8;
    raindrop.vel = vel;
  }

  //_previousExplosionRadius = explosionRadius;

  CGContextRestoreGState(cx);
}

- (NSString *)tooltipName {
  return @"Pixel Rain";
}

@end
