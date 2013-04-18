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

#import "PHCornerParticlesAnimation.h"

#import "PHBox2D.h"

@implementation PHCornerParticlesAnimation {
  CGFloat _advance;
  CGFloat _colorAdvance;
  NSTimeInterval _lastCreationTick;
}

- (id)init {
  if ((self = [super init])) {
    self.box2d.world->SetGravity(b2Vec2(0, 0));
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  _advance += self.secondsSinceLastTick;
  _colorAdvance += self.secondsSinceLastTick;

  if ([NSDate timeIntervalSinceReferenceDate] - _lastCreationTick > 0.1) {
    b2PolygonShape shape;
    shape.SetAsBox(2, 1);

    b2BodyDef bd;
    bd.type = b2_dynamicBody;
    b2Body* body = nil;

    CGFloat speed = 30;

    for (NSInteger ix = 0; ix < floor(self.bassDegrader.value * 2); ++ix) {
      bd.position.Set(0, 0);
      body = self.box2d.world->CreateBody(&bd);

      body->SetLinearVelocity(b2Vec2((sin(_advance) * 0.8 + 0.1) * speed + speed, (cos(_advance) * 0.8 + 0.1) * speed + speed));
      body->SetAngularVelocity((CGFloat)arc4random_uniform(100) / 100.0 * M_PI);
      body->CreateFixture(&shape, 1.0f);
    }

    for (NSInteger ix = 0; ix < floor(self.hihatDegrader.value * 2); ++ix) {
      bd.position.Set(kWallWidth, 0);
      body = self.box2d.world->CreateBody(&bd);
      body->SetUserData((void *)2);
      body->SetLinearVelocity(b2Vec2(-((sin(_advance) * 0.8 + 0.1) * speed + speed), (cos(-_advance) * 0.8 + 0.1) * speed + speed));
      body->SetAngularVelocity((CGFloat)arc4random_uniform(100) / 100.0 * M_PI);
      body->CreateFixture(&shape, 1.0f);
    }

    for (NSInteger ix = 0; ix < floor(self.vocalDegrader.value * 2); ++ix) {
      bd.position.Set(kWallWidth, kWallHeight);
      body = self.box2d.world->CreateBody(&bd);
      body->SetUserData((void *)2);
      body->SetLinearVelocity(b2Vec2(-((sin(-_advance) * 0.8 + 0.1) * speed + speed), -((cos(_advance) * 0.8 + 0.1) * speed + speed)));
      body->SetAngularVelocity((CGFloat)arc4random_uniform(100) / 100.0 * M_PI);
      body->CreateFixture(&shape, 1.0f);
    }

    for (NSInteger ix = 0; ix < floor(self.snareDegrader.value * 2); ++ix) {
      bd.position.Set(0, kWallHeight);
      body = self.box2d.world->CreateBody(&bd);
      body->SetUserData((void *)2);
      body->SetLinearVelocity(b2Vec2(((sin(-_advance) * 0.8 + 0.1) * speed + speed), -((cos(-_advance) * 0.8 + 0.1) * speed + speed)));
      body->SetAngularVelocity((CGFloat)arc4random_uniform(100) / 100.0 * M_PI);
      body->CreateFixture(&shape, 1.0f);
    }
    _lastCreationTick = [NSDate timeIntervalSinceReferenceDate];
  }

  [super renderBitmapInContext:cx size:size];

  NSInteger nAlive = 0, nDead = 0;
  for (b2Body* b = self.box2d.world->GetBodyList(); b; b = b->GetNext()) {
    b2Vec2 position = b->GetPosition();
    if (position.y < -5 || position.x < -5 || position.x > kWallWidth + 5 || position.y > kWallHeight + 5) {
      self.box2d.world->DestroyBody(b);
      nDead++;
    } else {
      nAlive++;
    }
  }
}

@end
