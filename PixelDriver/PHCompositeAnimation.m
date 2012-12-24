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

#import "PHCompositeAnimation.h"

@implementation PHCompositeAnimation {
  NSInteger _layerAnimationIndex[PHLaunchpadTopButtonCount];
  PHAnimation* _layerAnimation[PHLaunchpadTopButtonCount];
}

- (id)init {
  if ((self = [super init])) {
    [self reset];
  }
  return self;
}

- (NSString *)description {
  NSMutableString* description = [[super description] mutableCopy];
  for (NSInteger ix = 0; ix < PHLaunchpadTopButtonCount; ++ix) {
    [description appendFormat:@" %@", _layerAnimation[ix]];
  }
  [description appendString:@">"];
  return description;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
  for (NSUInteger ix = 0; ix < PHLaunchpadTopButtonCount; ++ix) {
    [coder encodeValueOfObjCType:@encode(NSInteger) at:&_layerAnimationIndex[ix]];
  }
}

- (id)initWithCoder:(NSCoder *)decoder {
  if ((self = [super init])) {
    NSArray* animations = [PHAnimation allAnimations];

    for (NSUInteger ix = 0; ix < PHLaunchpadTopButtonCount; ++ix) {
      [decoder decodeValueOfObjCType:@encode(NSInteger) at:&_layerAnimationIndex[ix]];

      if (_layerAnimationIndex[ix] >= 0) {
        _layerAnimation[ix] = animations[_layerAnimationIndex[ix]];
        _layerAnimation[ix].driver = self.driver;
      }
    }
  }
  return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
  PHCompositeAnimation* animation = [[[self class] allocWithZone:zone] init];

  animation.driver = self.driver;

  // Create fresh animations for this copy.
  NSArray* animations = [PHAnimation allAnimations];
  for (NSInteger ix = 0; ix < PHLaunchpadTopButtonCount; ++ix) {
    animation->_layerAnimationIndex[ix] = _layerAnimationIndex[ix];
    if (_layerAnimationIndex[ix] >= 0) {
      animation->_layerAnimation[ix] = animations[_layerAnimationIndex[ix]];
      animation->_layerAnimation[ix].driver = self.driver;
    }
  }

  return animation;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  @synchronized(self) {
    for (NSInteger ix = 0; ix < PHLaunchpadTopButtonCount; ++ix) {
      PHAnimation* animation = _layerAnimation[ix];
      if (nil != animation) {
        [animation renderBitmapInContext:cx size:size];
      }
    }
  }
}

- (NSInteger)indexOfAnimationForLayer:(PHLaunchpadTopButton)layer {
  return _layerAnimationIndex[layer];
}

- (void)setAnimationIndex:(NSInteger)animationIndex forLayer:(PHLaunchpadTopButton)layer {
  @synchronized(self) {
    _layerAnimationIndex[layer] = animationIndex;
    if (animationIndex >= 0) {
      NSArray* animations = [PHAnimation allAnimations];
      _layerAnimation[layer] = animations[animationIndex];
      _layerAnimation[layer].driver = self.driver;
    } else {
      _layerAnimation[layer] = nil;
    }
  }
}

- (void)setDriver:(PHAnimationDriver *)driver {
  [super setDriver:driver];

  for (NSUInteger ix = 0; ix < PHLaunchpadTopButtonCount; ++ix) {
    if (_layerAnimationIndex[ix] >= 0) {
      _layerAnimation[ix].driver = self.driver;
    }
  }
}

- (void)reset {
  @synchronized(self) {
    for (NSInteger ix = 0; ix < PHLaunchpadTopButtonCount; ++ix) {
      _layerAnimationIndex[ix] = -1;
      _layerAnimation[ix] = nil;
    }
  }
}

@end
