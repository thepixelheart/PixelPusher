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

#import "PHDrosteFilter.h"

@implementation PHDrosteFilter {
  CGFloat _rotationAdvance;
  CGFloat _xOffset;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  _rotationAdvance += self.secondsSinceLastTick;
  _xOffset += self.animationTick.hardwareState.numberOfRotationTicks;

  [super renderBitmapInContext:cx size:size];
}

- (NSString *)filterName {
  return @"CIDroste";
}

- (BOOL)useCroppedImage {
  return YES;
}

- (id)insetPoint0Value {
  CIVector *centerPoint = [self wallCenterValue];
  return [CIVector vectorWithX:centerPoint.X - kWallWidth / 2 + 1  Y:centerPoint.Y - kWallHeight / 2 + 1];
}

- (id)insetPoint1Value {
  CIVector *centerPoint = [self wallCenterValue];
  return [CIVector vectorWithX:centerPoint.X + kWallWidth / 2 - 1 Y:centerPoint.Y + kWallHeight / 2 - 1];
}

- (id)strandsValue {
  return @(1);
}

- (id)periodicityValue {
  return @(0);
}

- (id)rotationValue {
  return @(0);
}

- (id)zoomValue {
  return @(self.bassDegrader.value * 0.5 + 0.5);
}

- (NSString *)tooltipName {
  return @"Droste Filter";
}

@end
