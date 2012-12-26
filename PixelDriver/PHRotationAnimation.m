//
// Copyright 2012 Jeff Verkoeyen
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

#import "PHRotationAnimation.h"

@implementation PHRotationAnimation {
  CGFloat _rotationAdvance;
  CGFloat _direction;
}

+ (id)animationWithDirection:(CGFloat)direction {
  PHRotationAnimation* animation = [self animation];
  animation->_direction = direction;
  return animation;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  _rotationAdvance += self.secondsSinceLastTick * _direction * self.bassDegrader.value;

  CGContextTranslateCTM(cx, size.width / 2, size.height / 2);
  CGContextRotateCTM(cx, _rotationAdvance);
  CGContextTranslateCTM(cx, -size.width / 2, -size.height / 2);
}

- (NSString *)tooltipName {
  return _direction > 0 ? @"Rotate Clockwise" : @"Rotate Counter-Clockwise";
}

@end
