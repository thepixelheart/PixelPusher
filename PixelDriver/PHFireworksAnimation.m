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

#import "PHFireworksAnimation.h"

static const CGFloat kWallBuffer = -5;
static const NSTimeInterval kMinFireworkCreationInterval = 0.2;
static const NSInteger kRollingAverageCount = 200;
static const CGFloat kGravity = 9.8;

@interface PHFirework : NSObject
@property (nonatomic, assign) CGPoint position;
@property (nonatomic, assign) CGPoint velocity;
@property (nonatomic, assign) CGFloat r;
@property (nonatomic, assign) CGFloat g;
@property (nonatomic, assign) CGFloat b;
@property (nonatomic, assign) NSTimeInterval creationTime;
@property (nonatomic, assign) NSTimeInterval age;
@end

@implementation PHFirework
@end

@implementation PHFireworksAnimation {
  CGImageRef _imageOfPreviousFrame;
  NSMutableArray* _fireworks;
  NSMutableArray* _particles;
  NSTimeInterval _nextCreationTime;
  NSTimeInterval _nextExplosionTime;
  CGFloat _rollingSubBassAverage[kRollingAverageCount];
  CGFloat _rollingHitAverage[kRollingAverageCount];
  NSInteger _rollingAverageCount;
}

- (id)init {
  if ((self = [super init])) {
    _fireworks = [NSMutableArray array];
    _particles = [NSMutableArray array];
    memset(_rollingSubBassAverage, 0, sizeof(CGFloat) * kRollingAverageCount);
    memset(_rollingHitAverage, 0, sizeof(CGFloat) * kRollingAverageCount);
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  if (self.driver.unifiedSpectrum) {
    NSTimeInterval delta = self.secondsSinceLastTick;

    CGContextSetBlendMode(cx, kCGBlendModeLighten);
    if (_imageOfPreviousFrame) {
      CGContextSaveGState(cx);
      CGContextSetAlpha(cx, 0.96);
      CGContextDrawImage(cx, CGRectMake(1, 1, size.width - 2, size.height - 2), _imageOfPreviousFrame);
      CGContextRestoreGState(cx);
    }

    _rollingSubBassAverage[_rollingAverageCount % kRollingAverageCount] = self.driver.subBassAmplitude;
    _rollingHitAverage[_rollingAverageCount % kRollingAverageCount] = self.driver.hihatAmplitude;
    _rollingAverageCount++;

    NSInteger start = 0;
    NSInteger end = MIN(_rollingAverageCount, kRollingAverageCount);
    CGFloat bassAverage = 0;
    CGFloat hihatAverage = 0;
    for (NSInteger ix = start; ix < end; ++ix) {
      bassAverage += _rollingSubBassAverage[ix];
      hihatAverage += _rollingHitAverage[ix];
    }
    bassAverage /= (CGFloat)(end - start);
    hihatAverage /= (CGFloat)(end - start);

    NSArray* activeFireworks = [_fireworks copy];
    for (PHFirework* firework in activeFireworks) {
      firework.position = CGPointMake(firework.position.x + firework.velocity.x * delta,
                                      firework.position.y + firework.velocity.y * delta);

      firework.velocity = CGPointMake(firework.velocity.x,
                                      firework.velocity.y + delta * kGravity);

      CGFloat radius = 1.5;
      CGRect fireworkFrame = CGRectMake(firework.position.x - radius,
                                        firework.position.y - radius,
                                        radius * 2,
                                        radius * 2);
      CGContextSetRGBFillColor(cx, firework.r, firework.g, firework.b, 1);
      CGContextFillEllipseInRect(cx, fireworkFrame);

      if (firework.position.y - radius >= kWallHeight
          || firework.position.x + radius < 0
          || firework.position.x - radius >= kWallWidth) {
        [_fireworks removeObject:firework];
      }
    }
    NSArray* activeParticles = [_particles copy];
    for (PHFirework* firework in activeParticles) {
      firework.position = CGPointMake(firework.position.x + firework.velocity.x * delta,
                                      firework.position.y + firework.velocity.y * delta);
      firework.velocity = CGPointMake(firework.velocity.x,
                                      firework.velocity.y + delta * kGravity * 4);

      CGFloat radius = 1;
      CGRect fireworkFrame = CGRectMake(firework.position.x - radius,
                                        firework.position.y - radius,
                                        radius * 2,
                                        radius * 2);
      NSTimeInterval age = [NSDate timeIntervalSinceReferenceDate] - firework.creationTime;
      CGFloat alpha = 1 - MIN(1, age / firework.age);
      CGContextSetRGBFillColor(cx, firework.r, firework.g, firework.b, alpha);
      CGContextFillEllipseInRect(cx, fireworkFrame);

      if (alpha <= 0) {
        [_particles removeObject:firework];
      }
    }

    if (_fireworks.count > 0
        && [NSDate timeIntervalSinceReferenceDate] >= _nextExplosionTime
        && self.driver.hihatAmplitude >= hihatAverage + 0.2) {
      NSMutableArray* fireworksToExplode = [NSMutableArray array];
      for (PHFirework* firework in _fireworks) {
        if (firework.position.y < kWallHeight * 2 / 3) {
          [fireworksToExplode addObject:firework];
        }
      }
      NSInteger numberToExplode = fireworksToExplode.count - 1 - arc4random_uniform(fireworksToExplode.count * self.driver.hihatAmplitude);
      while (fireworksToExplode.count > numberToExplode) {
        PHFirework* sourceFirework = [fireworksToExplode objectAtIndex:arc4random_uniform((u_int32_t)fireworksToExplode.count)];
        [_fireworks removeObject:sourceFirework];

        for (NSInteger ix = 0; ix < arc4random_uniform(30) + 10; ++ix) {
          PHFirework* firework = [[PHFirework alloc] init];
          firework.position = sourceFirework.position;
          firework.velocity = CGPointMake((((CGFloat)arc4random_uniform(500)) - 250) / 20 + sourceFirework.velocity.x,
                                          (((CGFloat)arc4random_uniform(500)) - 250) / 20 + sourceFirework.velocity.y);
          firework.r = sourceFirework.r;
          firework.g = sourceFirework.g;
          firework.b = sourceFirework.b;
          firework.creationTime = [NSDate timeIntervalSinceReferenceDate];
          firework.age = (CGFloat)(arc4random_uniform(100) + 50) / 150;
          [_particles addObject:firework];
        }
        ++numberToExplode;
      }
      _nextExplosionTime = [NSDate timeIntervalSinceReferenceDate] + kMinFireworkCreationInterval * 4;
    }

    if ([NSDate timeIntervalSinceReferenceDate] >= _nextCreationTime && self.driver.subBassAmplitude >= bassAverage + 0.2) {
      for (NSInteger ix = 0; ix < arc4random_uniform(10 * self.driver.subBassAmplitude) + 1; ++ix) {
        PHFirework* firework = [[PHFirework alloc] init];
        firework.position = CGPointMake(((CGFloat)(arc4random_uniform(kWallWidth + kWallBuffer * 2) + kWallBuffer) * 100) / 100 - kWallBuffer, kWallHeight + 1.5);
        firework.velocity = CGPointMake( (((CGFloat)arc4random_uniform(500)) - 250) / 15,
                                        -(((CGFloat)arc4random_uniform(35)) + 70) / 4);
        firework.r = (CGFloat)(arc4random_uniform(128) + 128) / 255;
        firework.g = (CGFloat)(arc4random_uniform(128) + 128) / 255;
        firework.b = (CGFloat)(arc4random_uniform(128) + 128) / 255;
        firework.creationTime = [NSDate timeIntervalSinceReferenceDate];
        [_fireworks addObject:firework];
      }

      _nextCreationTime = [NSDate timeIntervalSinceReferenceDate] + kMinFireworkCreationInterval;
    }

    if (nil != _imageOfPreviousFrame) {
      CGImageRelease(_imageOfPreviousFrame);
    }
    _imageOfPreviousFrame = CGBitmapContextCreateImage(cx);
  }
}

@end
