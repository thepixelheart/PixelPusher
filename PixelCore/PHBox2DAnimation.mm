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

#import "PHBox2D.h"

static const CGFloat kScale = 2;

@implementation PHBox2DAnimation

- (id)init {
  if ((self = [super init])) {
    _box2d = [[PHBox2D alloc] initWithGravity:CGPointMake(0, -10)];
  }
  return self;
}

- (NSColor *)colorForBody:(b2Body *)body {
  return [NSColor whiteColor];
}

- (void)renderBodiesInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);
  CGContextScaleCTM(cx, 1, -1);
  CGContextTranslateCTM(cx, 0, -size.height);

  for (b2Body* b = _box2d.world->GetBodyList(); b; b = b->GetNext()) {
    const b2Transform& xf = b->GetTransform();
    for (b2Fixture* f = b->GetFixtureList(); f; f = f->GetNext()) {
      CGContextSaveGState(cx);

      switch (f->GetType()) {
        case b2Shape::e_circle: {
          b2CircleShape* circle = (b2CircleShape*)f->GetShape();

          b2Vec2 center = b2Mul(xf, circle->m_p);
          float32 radius = circle->m_radius;

          CGContextTranslateCTM(cx, center.x, center.y);
          CGContextSetFillColorWithColor(cx, [self colorForBody:b].CGColor);
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

          CGContextSetStrokeColorWithColor(cx, [self colorForBody:b].CGColor);
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
          CGContextSetStrokeColorWithColor(cx, [self colorForBody:b].CGColor);
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

          CGContextSetFillColorWithColor(cx, [self colorForBody:b].CGColor);
          CGContextEOFillPath(cx);
          break;
        }
        default:
          break;
      }
      
      CGContextRestoreGState(cx);
    }
  }
  CGContextRestoreGState(cx);
}

- (void)renderJointsInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);
  CGContextScaleCTM(cx, 1, -1);
  CGContextTranslateCTM(cx, 0, -size.height);

  for (b2Joint* b = _box2d.world->GetJointList(); b; b = b->GetNext()) {
    CGContextSaveGState(cx);

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
      default:
        break;
    }

    CGContextRestoreGState(cx);
  }
  CGContextRestoreGState(cx);
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
	int32 velocityIterations = 6;
	int32 positionIterations = 2;
  _box2d.world->Step(self.secondsSinceLastTick, velocityIterations, positionIterations);
}

- (NSString *)tooltipName {
  return @"Box 2D";
}

@end
