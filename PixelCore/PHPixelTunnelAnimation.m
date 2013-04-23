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

#import "PHPixelTunnelAnimation.h"

@implementation PHPixelTunnelAnimation {
  CGFloat _centerPointAdvance;
  CGFloat _rotationAdvance;
  CGFloat _colorAdvance;
}

- (id)init {
  if ((self = [super init])) {
    self.bassDegrader.deltaPerSecond = 0.2;
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);

  _centerPointAdvance += self.secondsSinceLastTick * 0.5;
  _colorAdvance += self.secondsSinceLastTick * (self.bassDegrader.value + 0.2);
  _rotationAdvance += self.secondsSinceLastTick * (self.hihatDegrader.value + 0.4);

  CGPoint center = CGPointMake(kWallWidth / 2, kWallHeight / 2);
  CGPoint start = CGPointMake(center.x + cos(_centerPointAdvance * 5) * (self.bassDegrader.value * 0.7 + 0.3) * (kWallWidth / 2 - 4),
                              center.y + sin(_centerPointAdvance * 3) * (self.bassDegrader.value * 0.7 + 0.3) * (kWallWidth / 2 - 4));
  CGFloat startRot = sin(_rotationAdvance) * M_PI;
  CGFloat endRot = 0;

  CGPoint distanceToCenter = CGPointMake(center.x - start.x, center.y - start.y);
  CGFloat radius = 0.5;
  while (radius <= kWallWidth / 2) {
    CGContextSaveGState(cx);
    CGFloat perc = radius / (kWallWidth / 2);

    CGPoint mid = CGPointMake(start.x + distanceToCenter.x * perc, start.y + distanceToCenter.y * perc);

    CGContextTranslateCTM(cx, mid.x, mid.y);
    
    CGRect rect = CGRectMake(-radius, -radius, radius * 2, radius * 2);
    CGFloat rot = startRot + (endRot - startRot) * perc;
    CGContextRotateCTM(cx, rot);

    CGFloat offset = _colorAdvance + radius * .05;
    CGFloat red = sin(offset * 7) * 0.5 + 0.5;
    CGFloat green = cos(offset * 13 + M_PI_2) * 0.5 + 0.5;
    CGFloat blue = sin(offset * 5 - M_PI_4) * 0.5 + 0.5;

    CGContextSetStrokeColorWithColor(cx, [NSColor colorWithDeviceRed:red green:green blue:blue alpha:1].CGColor);
    CGContextStrokeRect(cx, rect);
    radius += 0.5;
    CGContextRestoreGState(cx);
  }

  CGContextRestoreGState(cx);
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  [self renderBitmapInContext:cx size:size];
}

- (NSString *)tooltipName {
  return @"Pixel Tunnel";
}

@end
