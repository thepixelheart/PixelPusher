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

@interface PHCircularSliderCell : NSSliderCell
@end

@implementation PHCircularSliderCell

- (id)init {
  if ((self = [super init])) {
    [self setSliderType:NSCircularSlider];
  }
  return self;
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  cellFrame = [self drawingRectForBounds: cellFrame];
  _trackRect = cellFrame;

  NSPoint knobCenter;
  NSPoint point;
  float fraction, angle, radius;

  knobCenter = NSMakePoint(NSMidX(cellFrame), NSMidY(cellFrame));

  [dialImage drawInRect:cellFrame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];

  int knobDiameter = knobImage.size.width;
  int knobRadius = knobDiameter / 2;
  fraction = ([self floatValue] - [self minValue]) / ([self maxValue] - [self minValue]);
  angle = (fraction * (2.0 * M_PI)) - (M_PI / 2.0);
  radius = (cellFrame.size.height / 2) - knobDiameter;
  point = NSMakePoint((radius * cos(angle)) + knobCenter.x,
                      (radius * sin(angle)) + knobCenter.y);

  NSRect dotRect;
  dotRect.origin.x = point.x - knobRadius;
  dotRect.origin.y = point.y - knobRadius;
  dotRect.size = knobImage.size;
  [knobImage drawInRect:dotRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

@end

@implementation PHCircularSlider

+ (void)initialize {
  [PHCircularSlider setCellClass:[PHCircularSliderCell class]];
}

@end
