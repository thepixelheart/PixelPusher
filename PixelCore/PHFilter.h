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

#import "PHAnimation.h"

@interface PHFilter : PHAnimation

- (NSString *)filterName;

- (BOOL)useCroppedImage;
- (BOOL)isGenerator;
- (id)wallCenterValue;

- (id)radiusValue;
- (id)centerValue;
- (id)angleValue;
- (id)widthValue;
- (id)sharpnessValue;
- (id)zoomValue;
- (id)rotationValue;
- (id)periodicityValue;
- (id)insetPoint0Value;
- (id)insetPoint1Value;
- (id)strandsValue;
- (id)intensityValue;
- (id)evValue;
- (id)color0Value;
- (id)color1Value;
- (id)transformValue;
- (id)scaleValue;
- (id)countValue;

@end
