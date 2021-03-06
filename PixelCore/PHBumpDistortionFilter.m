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

#import "PHBumpDistortionFilter.h"

@implementation PHBumpDistortionFilter

- (NSString *)filterName {
  return @"CIBumpDistortion";
}

- (id)centerValue {
  return [self wallCenterValue];
}

- (id)radiusValue {
  return @(self.bassDegrader.value * kWallWidth);
}

- (id)scaleValue {
  return @(self.animationTick.hardwareState.fader * 2);
}

- (NSImage *)previewImage {
  return [NSImage imageNamed:@"bumpdistortion"];
}

- (NSString *)tooltipName {
  return @"Bump Distortion Filter";
}

@end
