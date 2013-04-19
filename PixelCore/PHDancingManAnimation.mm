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

#import "PHDancingManAnimation.h"

#import "PHBox2D.h"

@implementation PHDancingManAnimation {
  b2Body* _butt;
  b2Body* _torso;
  b2Body* _leftArm;
  b2Body* _rightArm;
  b2Body* _leftLeg;
  b2Body* _rightLeg;
  b2Body* _head;
	b2Body* m_bodies[4];
	b2Joint* m_joints[8];

  CGFloat _colorAdvance;

  CGFloat _danceDirection;
  BOOL _didUpdateForBeat;
}

- (id)init {
  if ((self = [super init])) {
    _danceDirection = 1;

    b2World* world = self.box2d.world;
		b2Body* ground = NULL;
		{
			b2BodyDef bd;
			ground = world->CreateBody(&bd);
		}

    b2PolygonShape shape;
    shape.SetAsBox(1, 1);

    CGFloat buttRadius = 5;
    CGFloat buttYOffset = -5;
    CGFloat torsoTopEdgeY = 4;
    CGFloat torsoRadius = 4;
    CGFloat headRadius = 4;

    b2BodyDef bd;
    bd.type = b2_dynamicBody;

    // Butt
    {
      b2PolygonShape shape;
      shape.SetAsBox(buttRadius, 1);
      bd.position.Set(kWallWidth / 2, kWallHeight / 2 + buttYOffset);
      _butt = world->CreateBody(&bd);
      _butt->CreateFixture(&shape, 5.0f);
      _butt->SetFixedRotation(YES);
    }

    {
      b2DistanceJointDef jd;
      b2Vec2 p1, p2, d;

      jd.frequencyHz = 2.0f;
      jd.dampingRatio = 0.0f;

      // Bottom-left
      jd.bodyA = ground;
      jd.bodyB = _butt;
      jd.localAnchorA.Set(-buttRadius + kWallWidth / 2, 0.0f);
      jd.localAnchorB.Set(-buttRadius, -0.5f);
      p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
      p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
      d = p2 - p1;
      jd.length = d.Length();
      m_joints[0] = world->CreateJoint(&jd);

      // Bottom-right
      jd.bodyA = ground;
      jd.bodyB = _butt;
      jd.localAnchorA.Set(buttRadius + kWallWidth / 2, 0.0f);
      jd.localAnchorB.Set(buttRadius, -0.5f);
      p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
      p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
      d = p2 - p1;
      jd.length = d.Length();
      m_joints[1] = world->CreateJoint(&jd);

      // Above
      jd.bodyA = ground;
      jd.bodyB = _butt;
      jd.frequencyHz = 1.5;
      jd.localAnchorA.Set(0.0f + kWallWidth / 2, kWallHeight / 2);
      jd.localAnchorB.Set(0.0f, 0.5f);
      p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
      p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
      d = p2 - p1;
      jd.length = d.Length() * 1.5;
      world->CreateJoint(&jd);
    }

    // Torso
    {
      bd.position.Set(kWallWidth / 2, kWallHeight / 2);
      _torso = world->CreateBody(&bd);

      b2Vec2 corners[3] = {
        b2Vec2(0, buttYOffset),
        b2Vec2(torsoRadius, torsoTopEdgeY),
        b2Vec2(-torsoRadius, torsoTopEdgeY)
      };
      b2PolygonShape shape;
      shape.Set(corners, 3);
      _torso->CreateFixture(&shape, 1.0f);
    }

    // Torso to butt
    {
      b2RevoluteJointDef jd;
      b2Vec2 p1, p2, d;

      // Bottom-left
      jd.bodyA = _butt;
      jd.bodyB = _torso;
      jd.collideConnected = true;
      jd.localAnchorA.Set(0, 0.0f);
      jd.localAnchorB.Set(0, buttYOffset);
      p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
      p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
      world->CreateJoint(&jd);
    }
    // Torso to wall
    {
      b2DistanceJointDef jd;
      b2Vec2 p1, p2, d;

      jd.frequencyHz = 3.0f;
      jd.dampingRatio = 0.0f;

      // Bottom-left
      jd.bodyA = ground;
      jd.bodyB = _torso;
      jd.localAnchorA.Set(kWallWidth / 2, kWallHeight);
      jd.localAnchorB.Set(0, torsoTopEdgeY);
      p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
      p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
      d = p2 - p1;
      jd.length = d.Length() * 0.75;
      m_joints[0] = world->CreateJoint(&jd);
    }

    // Left leg
    {
      b2PolygonShape shape;
      shape.SetAsBox(1, 5);
      bd.position.Set(kWallWidth / 2 - buttRadius, kWallHeight / 2 + buttYOffset - 5);
      _leftLeg = world->CreateBody(&bd);
      _leftLeg->CreateFixture(&shape, 1.0f);
    }

    // Right leg
    {
      b2PolygonShape shape;
      shape.SetAsBox(1, 5);
      bd.position.Set(kWallWidth / 2 + buttRadius, kWallHeight / 2 + buttYOffset - 5);
      _rightLeg = world->CreateBody(&bd);
      _rightLeg->CreateFixture(&shape, 1.0f);
    }

    // Left leg to butt
    {
      b2RevoluteJointDef jd;
      b2Vec2 p1, p2, d;

      // Bottom-left
      jd.bodyA = _butt;
      jd.bodyB = _leftLeg;
      jd.collideConnected = false;
      jd.localAnchorA.Set(-buttRadius, 0.0f);
      jd.localAnchorB.Set(0, 5);
      p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
      p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
      world->CreateJoint(&jd);
    }
    // Left leg to ground
    {
      b2RevoluteJointDef jd;
      b2Vec2 p1, p2, d;

      jd.bodyA = ground;
      jd.bodyB = _leftLeg;
      jd.collideConnected = false;
      jd.localAnchorA.Set(kWallWidth / 2 - buttRadius, 1);
      jd.localAnchorB.Set(-0.5, -5);
      p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
      p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
      world->CreateJoint(&jd);
    }
    // Right leg to butt
    {
      b2RevoluteJointDef jd;
      b2Vec2 p1, p2, d;

      // Bottom-left
      jd.bodyA = _butt;
      jd.bodyB = _rightLeg;
      jd.collideConnected = false;
      jd.localAnchorA.Set(buttRadius, 0.0f);
      jd.localAnchorB.Set(0, 5);
      p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
      p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
      world->CreateJoint(&jd);
    }
    // Right leg to ground
    {
      b2RevoluteJointDef jd;
      b2Vec2 p1, p2, d;

      jd.bodyA = ground;
      jd.bodyB = _rightLeg;
      jd.collideConnected = false;
      jd.localAnchorA.Set(kWallWidth / 2 + buttRadius, 1);
      jd.localAnchorB.Set(-0.5, -5);
      p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
      p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
      world->CreateJoint(&jd);
    }

    // Head
    {
      bd.position.Set(kWallWidth / 2, kWallHeight / 2 + torsoTopEdgeY + headRadius);

      b2CircleShape shape;
      shape.m_radius = headRadius;
      _head = world->CreateBody(&bd);
      _head->CreateFixture(&shape, 2.0f);
    }
    // Head to torso
    {
      b2RevoluteJointDef jd;
      b2Vec2 p1, p2, d;

      // Bottom-left
      jd.bodyA = _head;
      jd.bodyB = _torso;
      jd.collideConnected = true;
      jd.localAnchorA.Set(0, -headRadius);
      jd.localAnchorB.Set(0, torsoTopEdgeY);
      p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
      p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
      world->CreateJoint(&jd);
    }

    // Right arm
    {
      b2PolygonShape shape;
      shape.SetAsBox(5, 1);
      bd.position.Set(kWallWidth / 2 + 4 + 5, torsoTopEdgeY + kWallHeight / 2);
      _rightArm = world->CreateBody(&bd);
      _rightArm->CreateFixture(&shape, 1.0f);
    }

    // Left arm
    {
      b2PolygonShape shape;
      shape.SetAsBox(5, 1);
      bd.position.Set(kWallWidth / 2 - 4 - 5, torsoTopEdgeY + kWallHeight / 2);
      _leftArm = world->CreateBody(&bd);
      _leftArm->CreateFixture(&shape, 1.0f);
    }

    // Left arm to torso
    {
      b2RevoluteJointDef jd;
      b2Vec2 p1, p2;

      // Bottom-left
      jd.bodyA = _torso;
      jd.bodyB = _leftArm;
      jd.collideConnected = true;
      jd.localAnchorA.Set(-torsoRadius, torsoTopEdgeY);
      jd.localAnchorB.Set(5, 0);
      p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
      p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
      world->CreateJoint(&jd);
    }

    // Right arm to torso
    {
      b2RevoluteJointDef jd;
      b2Vec2 p1, p2;

      // Bottom-left
      jd.bodyA = _torso;
      jd.bodyB = _rightArm;
      jd.collideConnected = true;
      jd.localAnchorA.Set(torsoRadius, torsoTopEdgeY);
      jd.localAnchorB.Set(-5, 0);
      p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
      p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
      world->CreateJoint(&jd);
    }
  }
  return self;
}

- (NSColor *)colorForBody:(b2Body *)body {
  CGFloat offset = _colorAdvance;
  CGFloat red = sin(offset) * 0.5 + 0.5;
  CGFloat green = cos(offset * 5 + M_PI_2) * 0.5 + 0.5;
  CGFloat blue = sin(offset * 13 - M_PI_4) * 0.5 + 0.5;
  return [NSColor colorWithDeviceRed:red green:green blue:blue alpha:1];
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  [super renderBitmapInContext:cx size:size];

  [self renderBodiesInContext:cx size:size];
 // [self renderJointsInContext:cx size:size];

  _colorAdvance += self.secondsSinceLastTick * 0.2;

  if (self.animationTick.hardwareState.isBeating) {
    if (!_didUpdateForBeat) {
      b2Vec2 buttVelocity = _butt->GetLinearVelocity();
      float velChange = 0 - buttVelocity.x + _danceDirection * 80;
      float impulse = _butt->GetMass() * velChange;
      _butt->ApplyLinearImpulse(b2Vec2(impulse, 0), _butt->GetWorldCenter());

      _danceDirection = -_danceDirection;
      _didUpdateForBeat = YES;
    }
  } else {
    _didUpdateForBeat = NO;
  }

  if (self.animationTick.hardwareState.isUserButton1Pressed) {
    _leftArm->ApplyForce(b2Vec2(0, 10000), _leftArm->GetWorldCenter());
  }
  if (self.animationTick.hardwareState.isUserButton2Pressed) {
    _rightArm->ApplyForce(b2Vec2(0, 10000), _rightArm->GetWorldCenter());
  }
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  [self renderBitmapInContext:cx size:size];
}

- (NSString *)tooltipName {
  return @"Dancing Man";
}

@end
