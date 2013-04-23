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

#import "PHTriangleTileFilter.h"

@implementation PHTriangleTileFilter {
  CGFloat _rotationAdvance;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  _rotationAdvance += self.secondsSinceLastTick;

  [super renderBitmapInContext:cx size:size];
}


- (NSString *)filterName {
  return @"CITriangleTile";
}

- (id)centerValue {
  return [self wallCenterValue];
}

- (id)angleValue {
  return @(_rotationAdvance);
}

- (id)widthValue {
  return @(kWallWidth / 2);
}

- (NSImage *)previewImage {
  return [NSImage imageNamed:@"triangletile"];
}

- (NSString *)tooltipName {
  return @"Triangle Tile Filter";
}

@end
