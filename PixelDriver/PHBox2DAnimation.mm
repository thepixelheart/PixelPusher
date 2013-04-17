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

@implementation PHBox2DAnimation {
  b2World *_world;
  b2Body* _body;
  b2RevoluteJoint* _joint;
  NSInteger _nBodies;
}

- (void)dealloc {
  if (nil != _world) {
    delete _world;
  }
}

- (id)init {
  if ((self = [super init])) {
    b2Vec2 gravity(0.0f, -100.0f);
    _world = new b2World(gravity);

		b2Body* ground = NULL;
		{
			b2BodyDef bd;
			ground = _world->CreateBody(&bd);
		}

    b2BodyDef bd;
    bd.type = b2_dynamicBody;
    bd.allowSleep = false;
    bd.position.Set(0.0f, 0);
    b2Body* body = _world->CreateBody(&bd);

    b2PolygonShape shape;
    shape.SetAsBox(kWallHeight / 2, 0.5f, b2Vec2( kWallWidth / 2, 1.0f), 0.0);
    body->CreateFixture(&shape, 5.0f);
    shape.SetAsBox(kWallHeight / 2, 0.5f, b2Vec2(kWallWidth / 2, kWallHeight), 0.0);
    body->CreateFixture(&shape, 5.0f);
    shape.SetAsBox(0.5f, kWallHeight / 2, b2Vec2(kWallWidth / 2 - kWallHeight / 2, kWallHeight / 2), 0.0);
    body->CreateFixture(&shape, 5.0f);
    shape.SetAsBox(0.5f, kWallHeight / 2, b2Vec2(kWallWidth / 2 + kWallHeight / 2, kWallHeight / 2), 0.0);
    body->CreateFixture(&shape, 5.0f);

    b2RevoluteJointDef jd;
    jd.bodyA = ground;
    jd.bodyB = body;
    jd.localAnchorA.Set(kWallWidth / 2, kWallHeight / 2);
    jd.localAnchorB.Set(kWallWidth / 2, kWallHeight / 2);
    jd.referenceAngle = 0.0f;
    jd.motorSpeed = 1.15f * b2_pi;
    jd.maxMotorTorque = 1e8f;
    jd.enableMotor = true;
    _joint = (b2RevoluteJoint *)_world->CreateJoint(&jd);
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);
  CGContextScaleCTM(cx, 1, -1);
  CGContextTranslateCTM(cx, 0, -size.height);

  if (_nBodies < 20) {
    b2BodyDef bd;
    bd.type = b2_dynamicBody;
    bd.position.Set(kWallWidth / 2, kWallHeight / 2);
    b2Body* body = _world->CreateBody(&bd);

    b2PolygonShape shape;
    shape.SetAsBox(arc4random_uniform(3) + 1, arc4random_uniform(3) + 1);
    body->CreateFixture(&shape, 5.0f);
    ++_nBodies;
  }

  _joint->SetMotorSpeed(self.bassDegrader.value * 1.5 * b2_pi);

	int32 velocityIterations = 6;
	int32 positionIterations = 2;
  _world->Step(self.secondsSinceLastTick, velocityIterations, positionIterations);

  for (b2Body* b = _world->GetBodyList(); b; b = b->GetNext()) {
    const b2Transform& xf = b->GetTransform();
    for (b2Fixture* f = b->GetFixtureList(); f; f = f->GetNext()) {
      CGContextSaveGState(cx);

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

      CGContextRestoreGState(cx);
    }
  }
  CGContextRestoreGState(cx);
}

- (NSString *)tooltipName {
  return @"Box 2D";
}

@end
