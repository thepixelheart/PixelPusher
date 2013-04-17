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
  b2Body* _body;
  b2RevoluteJoint* _joint;
  NSInteger _nBodies;

	b2Vec2 m_offset;
	b2Body* m_chassis;
	b2Body* m_wheel;
	b2RevoluteJoint* m_motorJoint;
	bool m_motorOn;
	float32 m_motorSpeed;
}

- (void)dealloc {
  if (nil != _world) {
    delete _world;
  }
}
- (void)CreateLeg:(float32)s wheelAnchor:(const b2Vec2&)wheelAnchor
{
  b2Vec2 p1(5.4f * s, -6.1f * kScale);
  b2Vec2 p2(7.2f * s, -1.2f * kScale);
  b2Vec2 p3(4.3f * s, -1.9f * kScale);
  b2Vec2 p4(3.1f * s, 0.8f * kScale);
  b2Vec2 p5(6.0f * s, 1.5f * kScale);
  b2Vec2 p6(2.5f * s, 3.7f * kScale);

  b2FixtureDef fd1, fd2;
  fd1.filter.groupIndex = -1;
  fd2.filter.groupIndex = -1;
  fd1.density = 1.0f;
  fd2.density = 1.0f;

  b2PolygonShape poly1, poly2;

  if (s > 0.0f)
  {
    b2Vec2 vertices[3];

    vertices[0] = p1;
    vertices[1] = p2;
    vertices[2] = p3;
    poly1.Set(vertices, 3);

    vertices[0] = b2Vec2_zero;
    vertices[1] = p5 - p4;
    vertices[2] = p6 - p4;
    poly2.Set(vertices, 3);
  }
  else
  {
    b2Vec2 vertices[3];

    vertices[0] = p1;
    vertices[1] = p3;
    vertices[2] = p2;
    poly1.Set(vertices, 3);

    vertices[0] = b2Vec2_zero;
    vertices[1] = p6 - p4;
    vertices[2] = p5 - p4;
    poly2.Set(vertices, 3);
  }

  fd1.shape = &poly1;
  fd2.shape = &poly2;

  b2BodyDef bd1, bd2;
  bd1.type = b2_dynamicBody;
  bd2.type = b2_dynamicBody;
  bd1.position = m_offset;
  bd2.position = p4 + m_offset;

  bd1.angularDamping = 5.0f;
  bd2.angularDamping = 5.0f;

  b2Body* body1 = _world->CreateBody(&bd1);
  b2Body* body2 = _world->CreateBody(&bd2);

  body1->CreateFixture(&fd1);
  body2->CreateFixture(&fd2);

  b2DistanceJointDef djd;

  // Using a soft distance constraint can reduce some jitter.
  // It also makes the structure seem a bit more fluid by
  // acting like a suspension system.
  djd.dampingRatio = 0.5f;
  djd.frequencyHz = 10.0f;

  djd.Initialize(body1, body2, p2 + m_offset, p5 + m_offset);
  _world->CreateJoint(&djd);

  djd.Initialize(body1, body2, p3 + m_offset, p4 + m_offset);
  _world->CreateJoint(&djd);

  djd.Initialize(body1, m_wheel, p3 + m_offset, wheelAnchor + m_offset);
  _world->CreateJoint(&djd);

  djd.Initialize(body2, m_wheel, p6 + m_offset, wheelAnchor + m_offset);
  _world->CreateJoint(&djd);

  b2RevoluteJointDef rjd;

  rjd.Initialize(body2, m_chassis, p4 + m_offset);
  _world->CreateJoint(&rjd);
}

- (id)init {
  if ((self = [super init])) {

		m_offset.Set(kWallWidth / 2, kWallHeight);
		m_motorSpeed = 4.0f;
		m_motorOn = true;
		b2Vec2 pivot(0.0f, 0.8f);

    b2Vec2 gravity(0.0f, -10.0f);
    _world = new b2World(gravity);


		// Ground
		{
			b2BodyDef bd;
			b2Body* ground = _world->CreateBody(&bd);

			b2EdgeShape shape;
			shape.Set(b2Vec2(0.0f, 0.0f), b2Vec2(kWallWidth, 0.0f));
			ground->CreateFixture(&shape, 0.0f);
//
//			shape.Set(b2Vec2(0.0f, 0.0f), b2Vec2(0.0f, kWallHeight));
//			ground->CreateFixture(&shape, 0.0f);
//
//			shape.Set(b2Vec2(kWallWidth, 0.0f), b2Vec2(kWallWidth, kWallHeight));
//			ground->CreateFixture(&shape, 0.0f);
		}

		// Balls
		/*for (int32 i = 0; i < 40; ++i)
		{
			b2CircleShape shape;
			shape.m_radius = 0.25f;

			b2BodyDef bd;
			bd.type = b2_dynamicBody;
			bd.position.Set(-40.0f + 2.0f * i, 0.5f);

			b2Body* body = _world->CreateBody(&bd);
			body->CreateFixture(&shape, 1.0f);
		}*/

		// Chassis
		{
			b2PolygonShape shape;
			shape.SetAsBox(2.5f * kScale, 1.0f * kScale);

			b2FixtureDef sd;
			sd.density = 1.0f;
			sd.shape = &shape;
			sd.filter.groupIndex = -1;
			b2BodyDef bd;
			bd.type = b2_dynamicBody;
			bd.position = pivot + m_offset;
			m_chassis = _world->CreateBody(&bd);
			m_chassis->CreateFixture(&sd);
		}

		{
			b2CircleShape shape;
			shape.m_radius = 1.6f * kScale;

			b2FixtureDef sd;
			sd.density = 1.0f;
			sd.shape = &shape;
			sd.filter.groupIndex = -1;
			b2BodyDef bd;
			bd.type = b2_dynamicBody;
			bd.position = pivot + m_offset;
			m_wheel = _world->CreateBody(&bd);
			m_wheel->CreateFixture(&sd);
		}

		{
			b2RevoluteJointDef jd;
			jd.Initialize(m_wheel, m_chassis, pivot + m_offset);
			jd.collideConnected = false;
			jd.motorSpeed = m_motorSpeed;
			jd.maxMotorTorque = 400.0f * kScale;
			jd.enableMotor = m_motorOn;
			m_motorJoint = (b2RevoluteJoint*)_world->CreateJoint(&jd);
		}

		b2Vec2 wheelAnchor;

		wheelAnchor = pivot + b2Vec2(0.0f, -0.8f);

    [self CreateLeg:-kScale wheelAnchor:wheelAnchor];
    [self CreateLeg:kScale wheelAnchor:wheelAnchor];

		m_wheel->SetTransform(m_wheel->GetPosition(), 120.0f * b2_pi / 180.0f);
    [self CreateLeg:-kScale wheelAnchor:wheelAnchor];
    [self CreateLeg:kScale wheelAnchor:wheelAnchor];

		m_wheel->SetTransform(m_wheel->GetPosition(), -120.0f * b2_pi / 180.0f);
    [self CreateLeg:-kScale wheelAnchor:wheelAnchor];
    [self CreateLeg:kScale wheelAnchor:wheelAnchor];
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

  m_motorJoint->SetMotorSpeed(m_motorSpeed * self.bassDegrader.value * 4);
  CGContextTranslateCTM(cx, -m_chassis->GetPosition().x + kWallWidth / 2, -m_chassis->GetPosition().y + kWallHeight / 2);

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
  CGContextRestoreGState(cx);
}

- (NSString *)tooltipName {
  return @"Box 2D";
}

@end
