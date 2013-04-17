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

#import "PHBox2DAnimation.h"

#import "Box2D.h"

static const CGFloat kScale = 2;

@implementation PHBox2DAnimation {
  b2World *_world;
	b2Body* m_bodies[4];
	b2Joint* m_joints[8];
  CGFloat _advance;
}

- (void)dealloc {
  if (nil != _world) {
    delete _world;
  }
}

- (id)init {
  if ((self = [super init])) {
    b2Vec2 gravity(0.0f, -10.0f);
    _world = new b2World(gravity);

		b2Body* ground = NULL;
		{
			b2BodyDef bd;
			ground = _world->CreateBody(&bd);
		}

    b2PolygonShape shape;
    shape.SetAsBox(1, 1);

    b2BodyDef bd;
    bd.type = b2_dynamicBody;

    bd.position.Set(-5.0f + kWallWidth / 2, -5.0f + kWallHeight / 2);
    m_bodies[0] = _world->CreateBody(&bd);
    m_bodies[0]->CreateFixture(&shape, 5.0f);

    bd.position.Set(5.0f + kWallWidth / 2, -5.0f + kWallHeight / 2);
    m_bodies[1] = _world->CreateBody(&bd);
    m_bodies[1]->CreateFixture(&shape, 5.0f);

    bd.position.Set(5.0f + kWallWidth / 2, 5.0f + kWallHeight / 2);
    m_bodies[2] = _world->CreateBody(&bd);
    m_bodies[2]->CreateFixture(&shape, 5.0f);

    bd.position.Set(-5.0f + kWallWidth / 2, 5.0f + kWallHeight / 2);
    m_bodies[3] = _world->CreateBody(&bd);
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
    m_joints[0] = _world->CreateJoint(&jd);

    jd.bodyA = ground;
    jd.bodyB = m_bodies[1];
    jd.localAnchorA.Set(5.0f + kWallWidth / 2, 0.0f);
    jd.localAnchorB.Set(0.5f, -0.5f);
    p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
    p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
    d = p2 - p1;
    jd.length = d.Length();
    m_joints[1] = _world->CreateJoint(&jd);

    jd.bodyA = ground;
    jd.bodyB = m_bodies[2];
    jd.localAnchorA.Set(10.0f + kWallWidth / 2, 0.0f + kWallHeight - 4);
    jd.localAnchorB.Set(0.5f, 0.5f);
    p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
    p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
    d = p2 - p1;
    jd.length = d.Length();
    m_joints[2] = _world->CreateJoint(&jd);

    jd.bodyA = ground;
    jd.bodyB = m_bodies[3];
    jd.localAnchorA.Set(-10.0f + kWallWidth / 2, 0.0f + kWallHeight - 4);
    jd.localAnchorB.Set(-0.5f, 0.5f);
    p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
    p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
    d = p2 - p1;
    jd.length = d.Length();
    m_joints[3] = _world->CreateJoint(&jd);

    jd.bodyA = m_bodies[0];
    jd.bodyB = m_bodies[1];
    jd.localAnchorA.Set(0.5f, 0.0f);
    jd.localAnchorB.Set(-0.5f, 0.0f);;
    p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
    p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
    d = p2 - p1;
    jd.length = d.Length();
    m_joints[4] = _world->CreateJoint(&jd);

    jd.bodyA = m_bodies[1];
    jd.bodyB = m_bodies[2];
    jd.localAnchorA.Set(0.0f, 0.5f);
    jd.localAnchorB.Set(0.0f, -0.5f);
    p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
    p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
    d = p2 - p1;
    jd.length = d.Length();
    m_joints[5] = _world->CreateJoint(&jd);

    jd.bodyA = m_bodies[2];
    jd.bodyB = m_bodies[3];
    jd.localAnchorA.Set(-0.5f, 0.0f);
    jd.localAnchorB.Set(0.5f, 0.0f);
    p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
    p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
    d = p2 - p1;
    jd.length = d.Length();
    m_joints[6] = _world->CreateJoint(&jd);

    jd.bodyA = m_bodies[3];
    jd.bodyB = m_bodies[0];
    jd.localAnchorA.Set(0.0f, -0.5f);
    jd.localAnchorB.Set(0.0f, 0.5f);
    p1 = jd.bodyA->GetWorldPoint(jd.localAnchorA);
    p2 = jd.bodyB->GetWorldPoint(jd.localAnchorB);
    d = p2 - p1;
    jd.length = d.Length();
    m_joints[7] = _world->CreateJoint(&jd);
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);
  CGContextScaleCTM(cx, 1, -1);
  CGContextTranslateCTM(cx, 0, -size.height);

	int32 velocityIterations = 6;
	int32 positionIterations = 2;
  _world->Step(self.secondsSinceLastTick, velocityIterations, positionIterations);

  _advance += self.secondsSinceLastTick * 5;
  m_bodies[0]->ApplyLinearImpulse(b2Vec2(self.bassDegrader.value * 100 * sin(_advance), 0), m_bodies[0]->GetPosition());
  m_bodies[1]->ApplyLinearImpulse(b2Vec2(self.bassDegrader.value * 100 * sin(_advance), 0), m_bodies[1]->GetPosition());

  for (b2Body* b = _world->GetBodyList(); b; b = b->GetNext()) {
    const b2Transform& xf = b->GetTransform();
    for (b2Fixture* f = b->GetFixtureList(); f; f = f->GetNext()) {
      CGContextSaveGState(cx);

      switch (f->GetType()) {
        case b2Shape::e_circle: {
          b2CircleShape* circle = (b2CircleShape*)f->GetShape();

          b2Vec2 center = b2Mul(xf, circle->m_p);
          float32 radius = circle->m_radius;

          CGContextTranslateCTM(cx, center.x, center.y);
          CGContextFillEllipseInRect(cx, CGRectMake(-radius, -radius, radius * 2, radius * 2));
          break;
        }

        case b2Shape::e_edge:
        {
          b2EdgeShape* edge = (b2EdgeShape*)f->GetShape();
          b2Vec2 v1 = b2Mul(xf, edge->m_vertex1);
          b2Vec2 v2 = b2Mul(xf, edge->m_vertex2);

          CGContextBeginPath(cx);
          CGContextMoveToPoint(cx, v1.x, v1.y);
          CGContextAddLineToPoint(cx, v2.x, v2.y);

          CGContextSetStrokeColorWithColor(cx, [NSColor whiteColor].CGColor);
          CGContextStrokePath(cx);
        }
          break;

        case b2Shape::e_chain:
        {
          b2ChainShape* chain = (b2ChainShape*)f->GetShape();
          int32 count = chain->m_count;
          const b2Vec2* vertices = chain->m_vertices;

          b2Vec2 v1 = b2Mul(xf, vertices[0]);
          CGContextBeginPath(cx);
          for (int32 i = 1; i < count; ++i)
          {
            b2Vec2 v2 = b2Mul(xf, vertices[i]);
            if (i == 1) {
              CGContextMoveToPoint(cx, v1.x, v1.y);
            }
            CGContextAddLineToPoint(cx, v2.x, v2.y);

            v1 = v2;
          }
          CGContextSetStrokeColorWithColor(cx, [NSColor whiteColor].CGColor);
          CGContextStrokePath(cx);
        }
          break;

        case b2Shape::e_polygon: {
          b2PolygonShape* poly = (b2PolygonShape*)f->GetShape();
          int32 vertexCount = poly->m_vertexCount;
          b2Assert(vertexCount <= b2_maxPolygonVertices);

          CGContextBeginPath(cx);

          for (int32 i = 0; i < vertexCount; ++i) {
            b2Vec2 vec = b2Mul(xf, poly->m_vertices[i]);
            if (i == 0) {
              CGContextMoveToPoint(cx, vec.x, vec.y);
            } else {
              CGContextAddLineToPoint(cx, vec.x, vec.y);
            }
          }

          CGContextSetFillColorWithColor(cx, [NSColor whiteColor].CGColor);
          CGContextEOFillPath(cx);
          break;
        }
      }

      CGContextRestoreGState(cx);
    }
  }

  for (b2Joint* b = _world->GetJointList(); b; b = b->GetNext()) {
    CGContextSaveGState(cx);

    b2Body* bodyA = b->GetBodyA();
    b2Body* bodyB = b->GetBodyB();
    const b2Transform& xf1 = bodyA->GetTransform();
    const b2Transform& xf2 = bodyB->GetTransform();
    b2Vec2 x1 = xf1.p;
    b2Vec2 x2 = xf2.p;
    b2Vec2 p1 = b->GetAnchorA();
    b2Vec2 p2 = b->GetAnchorB();

    switch (b->GetType()) {
      case e_distanceJoint:
      {
        CGContextBeginPath(cx);
        CGContextMoveToPoint(cx, p1.x, p1.y);
        CGContextAddLineToPoint(cx, p2.x, p2.y);

        CGContextSetStrokeColorWithColor(cx, [NSColor redColor].CGColor);
        CGContextStrokePath(cx);
      }
        break;
    }
    
    CGContextRestoreGState(cx);
  }
  CGContextRestoreGState(cx);
}

- (NSString *)tooltipName {
  return @"Box 2D";
}

@end
