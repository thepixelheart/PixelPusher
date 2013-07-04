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

#import "PHCircularSlider.h"

typedef enum {
  PHCircularSliderTrackingMode_Gutter,
  PHCircularSliderTrackingMode_Horizontal,
  PHCircularSliderTrackingMode_Vertical
} PHCircularSliderTrackingMode;

@interface PHCircularSlider ()
@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL action;
@end

@implementation PHCircularSlider {
  NSImage* _backgroundImage;
  NSImage* _dotImage;

  // Tracking
  NSPoint _trackingStartPoint;
  float _trackingStartValue;
  PHCircularSliderTrackingMode _trackingMode;

  float _floatValue;
}

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    _backgroundImage = [NSImage imageNamed:@"circularslider"];
    _dotImage = [NSImage imageNamed:@"circularslider_knob"];
  }
  return self;
}

#pragma mark - Layout

- (void)sizeToFit {
  CGRect frame = self.frame;
  frame.size = _backgroundImage.size;
  self.frame = frame;
}

#pragma mark - Rendering

- (void)drawRect:(NSRect)dirtyRect {
  CGRect cellFrame = self.bounds;

  NSPoint knobCenter = NSMakePoint(NSMidX(cellFrame), NSMidY(cellFrame));

  CGRect imageFrame = CGRectMake(floorf((cellFrame.size.width - _backgroundImage.size.width) / 2.) + cellFrame.origin.x,
                                 floorf((cellFrame.size.height - _backgroundImage.size.height) / 2.) + cellFrame.origin.y, _backgroundImage.size.width, _backgroundImage.size.height);
  [_backgroundImage drawInRect:imageFrame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];

  CGContextRef cx = [[NSGraphicsContext currentContext] graphicsPort];
  CGContextTranslateCTM(cx, knobCenter.x, knobCenter.y);

  int knobDiameter = _dotImage.size.width;
  int knobRadius = knobDiameter / 2;
  float fraction = ([self floatValue] - [self minValue]) / ([self maxValue] - [self minValue]);

  float angle = 0;
  if (_circularSliderType == PHCircularSliderType_Volume) {
    angle = M_PI - M_PI * 30. / 180. - fraction * (M_PI * 2 - M_PI * 60 / 180.0);
  }
  ;//  angle = (fraction * (2.0 * M_PI)) + M_PI;
  float radius = (_backgroundImage.size.height / 4);
  CGContextRotateCTM(cx, angle);
  NSPoint point = NSMakePoint(0, radius);

  NSRect dotRect;
  dotRect.origin.x = point.x - knobRadius;
  dotRect.origin.y = point.y - knobRadius;
  dotRect.size = _dotImage.size;
  [_dotImage drawInRect:dotRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

#pragma mark - Mouse Handling

- (void)mouseDown:(NSEvent *)event {
  if (![self isEnabled]) {
    return;
  }

  _trackingMode = PHCircularSliderTrackingMode_Gutter;

  _trackingStartPoint = [self convertPoint:[event locationInWindow] fromView:nil];
  _trackingStartValue = [self floatValue];
}

- (void)mouseDragged:(NSEvent *)event {
  if (![self isEnabled]) {
    return;
  }

  NSPoint location = [self convertPoint:[event locationInWindow] fromView:nil];
  CGFloat deltaX = location.x - _trackingStartPoint.x;
  CGFloat deltaY = location.y - _trackingStartPoint.y;

  if (_trackingMode == PHCircularSliderTrackingMode_Gutter) {
    if (fabs(deltaX) > 5 || fabs(deltaY) > 5) {
      if (fabs(deltaX) > fabs(deltaY)) {
        _trackingMode = PHCircularSliderTrackingMode_Horizontal;
      } else {
        _trackingMode = PHCircularSliderTrackingMode_Vertical;
      }
    }
  }

  if (_trackingMode != PHCircularSliderTrackingMode_Gutter) {
    CGFloat delta = 0;
    if (_trackingMode == PHCircularSliderTrackingMode_Horizontal) {
      delta = deltaX;
    } else {
      delta = deltaY;
    }

    [self setFloatValue:_trackingStartValue + delta / 200];
    [self setNeedsDisplay:YES];

    [self sendAction:self.action to:self.target];
  }
}

#pragma mark - Private Methods

- (float)minValue {
  return 0;
}

- (float)maxValue {
  return 1;
}

- (void)setFloatValue:(float)aFloat {
  if ([self circularSliderType] == PHCircularSliderType_Volume) {
    // 0/1 at the top, going clockwise.
    aFloat = MIN(1, MAX(0, aFloat));
  }

  _floatValue = aFloat;
}

- (float)floatValue {
  return _floatValue;
}

#pragma mark - Public Methods

- (void)setCircularSliderType:(PHCircularSliderType)circularSliderType {
  _circularSliderType = circularSliderType;
  if (circularSliderType == PHCircularSliderType_Volume) {
  }
  [self setNeedsDisplay:YES];
}

- (void)setVolume:(CGFloat)volume {
  self.floatValue = volume;
}

- (CGFloat)volume {
  return self.floatValue;
}

@end
