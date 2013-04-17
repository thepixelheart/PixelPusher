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
	b2Body* m_bodies[4];
	b2Joint* m_joints[8];
  CGFloat _advance;
}

- (id)init {
  if ((self = [super init])) {
    b2World* world = self.box2d.world;
		b2Body* ground = NULL;
		{
			b2BodyDef bd;
			ground = world->CreateBody(&bd);
		}

    b2PolygonShape shape;
    shape.SetAsBox(1, 1);

    b2BodyDef bd;
    bd.type = b2_dynamicBody;

    bd.position.Set(-5.0f + kWallWidth / 2, -5.0f + kWallHeight / 2);
    m_bodies[0] = world->CreateBody(&bd);
    m_bodies[0]->CreateFixture(&shape, 5.0f);

    bd.position.Set(5.0f + kWallWidth / 2, -5.0f + kWallHeight / 2);
    m_bodies[1] = world->CreateBody(&bd);
    m_bodies[1]->CreateFixture(&shape, 5.0f);

    bd.position.Set(5.0f + kWallWidth / 2, 5.0f + kWallHeight / 2);
    m_bodies[2] = world->CreateBody(&bd);
    m_bodies[2]->CreateFixture(&shape, 5.0f);

    bd.position.Set(-5.0f + kWallWidth / 2, 5.0f + kWallHeight / 2);
    m_bodies[3] = world->CreateBody(&bd);
    m_bodies[3]->CreateFixture(&shape, 5.0f);

    b2DistanceJointDef jd;
    b2Vec2 p1, p2, d;

    jd.frequencyHz = 2.0f;
    jd.dampingRatio = 0.0f;

    jd.bodyA = ground;
    jd.bodyB = m_bodies[0];
    jd.localAnchorA.Set(-5.0f + kWallWidth / 2, 0.0f);
    jd.localAnchorB.Set(-0.5f, -0.5f);
    p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
    p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
    d = p2 - p1;
    jd.length = d.Length();
    m_joints[0] = world->CreateJoint(&jd);

    jd.bodyA = ground;
    jd.bodyB = m_bodies[1];
    jd.localAnchorA.Set(5.0f + kWallWidth / 2, 0.0f);
    jd.localAnchorB.Set(0.5f, -0.5f);
    p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
    p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
    d = p2 - p1;
    jd.length = d.Length();
    m_joints[1] = world->CreateJoint(&jd);

    jd.bodyA = ground;
    jd.bodyB = m_bodies[2];
    jd.localAnchorA.Set(10.0f + kWallWidth / 2, 0.0f + kWallHeight - 4);
    jd.localAnchorB.Set(0.5f, 0.5f);
    p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
    p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
    d = p2 - p1;
    jd.length = d.Length();
    m_joints[2] = world->CreateJoint(&jd);

    jd.bodyA = ground;
    jd.bodyB = m_bodies[3];
    jd.localAnchorA.Set(-10.0f + kWallWidth / 2, 0.0f + kWallHeight - 4);
    jd.localAnchorB.Set(-0.5f, 0.5f);
    p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
    p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
    d = p2 - p1;
    jd.length = d.Length();
    m_joints[3] = world->CreateJoint(&jd);

    jd.bodyA = m_bodies[0];
    jd.bodyB = m_bodies[1];
    jd.localAnchorA.Set(0.5f, 0.0f);
    jd.localAnchorB.Set(-0.5f, 0.0f);;
    p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
    p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
    d = p2 - p1;
    jd.length = d.Length();
    m_joints[4] = world->CreateJoint(&jd);

    jd.bodyA = m_bodies[1];
    jd.bodyB = m_bodies[2];
    jd.localAnchorA.Set(0.0f, 0.5f);
    jd.localAnchorB.Set(0.0f, -0.5f);
    p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
    p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
    d = p2 - p1;
    jd.length = d.Length();
    m_joints[5] = world->CreateJoint(&jd);

    jd.bodyA = m_bodies[2];
    jd.bodyB = m_bodies[3];
    jd.localAnchorA.Set(-0.5f, 0.0f);
    jd.localAnchorB.Set(0.5f, 0.0f);
    p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
    p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
    d = p2 - p1;
    jd.length = d.Length();
    m_joints[6] = world->CreateJoint(&jd);

    jd.bodyA = m_bodies[3];
    jd.bodyB = m_bodies[0];
    jd.localAnchorA.Set(0.0f, -0.5f);
    jd.localAnchorB.Set(0.0f, 0.5f);
    p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
    p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
    d = p2 - p1;
    jd.length = d.Length();
    m_joints[7] = world->CreateJoint(&jd);
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  [super renderBitmapInContext:cx size:size];

  _advance += self.secondsSinceLastTick * 5;
  m_bodies[0]->ApplyLinearImpulse(b2Vec2(self.bassDegrader.value * 100 * sin(_advance), 0), m_bodies[0]->GetPosition());
  m_bodies[1]->ApplyLinearImpulse(b2Vec2(self.bassDegrader.value * 100 * sin(_advance), 0), m_bodies[1]->GetPosition());
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  [self renderBitmapInContext:cx size:size];
}

- (NSString *)tooltipName {
  return @"Dancing Man";
}

@end
