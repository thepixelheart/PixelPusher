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

#import "PHEightfoldReflectedTileFilter.h"

@implementation PHEightfoldReflectedTileFilter {
  CGFloat _rotationAdvance;
  CGFloat _width;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  _rotationAdvance += self.secondsSinceLastTick;
  // TODO: Make the width modified by the relative offset bar.
  _width += (CGFloat)self.animationTick.hardwareState.numberOfRotationTicks * 0.1;

  _width = MAX(4, MIN(kWallWidth, _width));

  [super renderBitmapInContext:cx size:size];
}

- (NSString *)filterName {
  return @"CIEightfoldReflectedTile";
}

- (id)centerValue {
  return [self wallCenterValue];
}

- (id)angleValue {
  return @(_rotationAdvance);
}

- (id)widthValue {
  return @(_width);
}

- (NSString *)tooltipName {
  return @"Eightfold Reflected Tile Filter";
}

@end
