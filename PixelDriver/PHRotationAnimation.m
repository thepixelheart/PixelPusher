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

static NSString* const kDirectionKey = @"kDirectionKey";

@implementation PHRotationAnimation {
  CGFloat _rotationAdvance;
  CGFloat _direction;
}

+ (id)animationWithDirection:(CGFloat)direction {
  PHRotationAnimation* animation = [self animation];
  animation->_direction = direction;
  return animation;
}

- (id)copyWithZone:(NSZone *)zone {
  PHRotationAnimation* copy = [[self.class allocWithZone:zone] init];
  copy->_direction = _direction;
  return copy;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGFloat direction = _direction;
  if (self.systemState.isUserButton1Pressed
      || self.systemState.isUserButton2Pressed) {
    direction = -direction;
  }

  if (self.animationTick.hardwareState.numberOfRotationTicks != 0) {
    _rotationAdvance += (CGFloat)self.animationTick.hardwareState.numberOfRotationTicks * M_PI * 3 / 180;
  } else {
    _rotationAdvance += self.secondsSinceLastTick * direction * self.bassDegrader.value;
  }

  CGContextTranslateCTM(cx, size.width / 2, size.height / 2);
  CGContextRotateCTM(cx, _rotationAdvance);
  CGContextTranslateCTM(cx, -size.width / 2, -size.height / 2);
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  PHSpritesheet* spritesheet = [[PHSpritesheet alloc] initWithName:@"pixelheart" spriteSize:CGSizeMake(26, 23)];
  CGImageRef imageRef = [spritesheet imageAtX:0 y:0];

  CGSize spriteSize = spritesheet.spriteSize;
  CGRect heartFrame = CGRectMake(floorf((size.width - spriteSize.width) / 2),
                                 floorf((size.height - spriteSize.height) / 2),
                                 spriteSize.width,
                                 spriteSize.height);

  CGContextTranslateCTM(cx, size.width / 2, size.height / 2);
  CGContextRotateCTM(cx, _direction * M_PI_4);
  CGContextTranslateCTM(cx, -size.width / 2, -size.height / 2);
  heartFrame = CGRectInset(heartFrame, 3, 3);
  CGContextDrawImage(cx, heartFrame, imageRef);

  CGImageRelease(imageRef);
}

- (id)definingProperties {
  return @{kDirectionKey:@(_direction)};
}

- (void)setDefiningProperties:(id)definingProperties {
  _direction = [definingProperties[kDirectionKey] floatValue];
}

- (NSString *)tooltipName {
  if (_direction > 0) {
    return @"Rotate Clockwise";
  } else if (_direction < 0) {
    return @"Rotate Counter-Clockwise";
  } else {
    return @"Programmatic Rotation";
  }
}

- (BOOL)isPipeAnimation {
  return YES;
}

- (NSArray *)categories {
  return @[
    PHAnimationCategoryPipes
  ];
}

@end
