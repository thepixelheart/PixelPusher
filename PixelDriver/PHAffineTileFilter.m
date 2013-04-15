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

#import "PHAffineTileFilter.h"

@implementation PHAffineTileFilter {
  CGFloat _rotation;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  _rotation += self.animationTick.hardwareState.numberOfRotationTicks;

  [super renderBitmapInContext:cx size:size];
}

- (NSString *)filterName {
  return @"CIAffineTile";
}

- (BOOL)useCroppedImage {
  return YES;
}

- (id)transformValue {
  NSAffineTransform *transform = [NSAffineTransform transform];
  [transform translateXBy:kWallWidth / 2 yBy:kWallHeight / 2];
  [transform rotateByDegrees:_rotation];
  [transform scaleBy:(self.animationTick.hardwareState.fader + 0.5) * 0.7 + 0.3];
  [transform translateXBy:-kWallWidth / 2 yBy:-kWallHeight / 2];
//  [transform translateXBy:1 yBy:1];
  return transform;
}

- (NSString *)tooltipName {
  return @"Affine Tile Filter";
}

@end
