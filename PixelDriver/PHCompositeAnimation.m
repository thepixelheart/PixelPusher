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
  NSArray* _classes;
  NSString* _name;
}

+ (id)animationWithLayers:(NSArray *)layers animations:(NSArray *)animations name:(NSString *)name {
  PHCompositeAnimation* animation = [super animation];
  animation->_name = [name copy];

  for (NSInteger ix = 0; ix < PHLaunchpadTopButtonCount && ix < layers.count; ++ix) {
    PHAnimation* layerAnimation = layers[ix];
    animation->_layerAnimation[ix] = layerAnimation;
    for (PHAnimation* animationInList in animations) {
      if ([animationInList.class isSubclassOfClass:layerAnimation.class]
          && [layerAnimation.class isSubclassOfClass:animationInList.class]) {
        animation->_layerAnimationIndex[ix] = [animations indexOfObject:animationInList];
        break;
      }
    }
  }
  return animation;
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

      if (_layerAnimationIndex[ix] >= 0 && _layerAnimationIndex[ix] < animations.count) {
        _layerAnimation[ix] = animations[_layerAnimationIndex[ix]];
        _layerAnimation[ix].systemState = self.systemState;
      } else {
        // This animation no longer exists.
        _layerAnimationIndex[ix] = -1;
      }
    }
  }
  return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
  PHCompositeAnimation* animation = [[[self class] allocWithZone:zone] init];

  animation.systemState = self.systemState;

  // Create fresh animations for this copy.
  NSArray* animations = [PHAnimation allAnimations];
  for (NSInteger ix = 0; ix < PHLaunchpadTopButtonCount; ++ix) {
    animation->_layerAnimationIndex[ix] = _layerAnimationIndex[ix];
    if (_layerAnimationIndex[ix] >= 0) {
      animation->_layerAnimation[ix] = animations[_layerAnimationIndex[ix]];
      animation->_layerAnimation[ix].systemState = self.systemState;
    }
  }

  animation->_name = [_name copyWithZone:zone];

  return animation;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  @synchronized(self) {
    for (NSInteger ix = 0; ix < PHLaunchpadTopButtonCount; ++ix) {
      PHAnimation* animation = _layerAnimation[ix];
      [animation bitmapWillStartRendering];
      [animation renderBitmapInContext:cx size:size];
      [animation bitmapDidFinishRendering];
    }
  }
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  for (PHLaunchpadTopButton ix = 0; ix < PHLaunchpadTopButtonCount; ++ix) {
    NSInteger animationIndex = _layerAnimationIndex[ix];;
    if (animationIndex >= 0) {
      PHAnimation* animation = _layerAnimation[ix];
      CGContextRef subContextRef = PHCreate8BitBitmapContextWithSize(CGSizeMake(size.width, size.height));
      [animation renderPreviewInContext:subContextRef size:size];

      CGImageRef imageRef = CGBitmapContextCreateImage(subContextRef);
      CGContextDrawImage(cx, CGRectMake((ix % 4) * size.width / 4,
                                        (ix / 4) * size.height / 2 + 2,
                                        size.width / 4, size.height / 2 - 4), imageRef);
      CGImageRelease(imageRef);
      CGContextRelease(subContextRef);
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
      _layerAnimation[layer].systemState = self.systemState;
    } else {
      _layerAnimation[layer] = nil;
    }
  }
}

- (void)setSystemState:(PHSystemState *)driver {
  [super setSystemState:driver];

  for (NSUInteger ix = 0; ix < PHLaunchpadTopButtonCount; ++ix) {
    if (_layerAnimationIndex[ix] >= 0) {
      _layerAnimation[ix].systemState = self.systemState;
    }
  }
}

- (void)setAnimationTick:(PHAnimationTick *)animationTick {
  [super setAnimationTick:animationTick];

  for (NSUInteger ix = 0; ix < PHLaunchpadTopButtonCount; ++ix) {
    if (_layerAnimationIndex[ix] >= 0) {
      _layerAnimation[ix].animationTick = self.animationTick;
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

- (NSString *)tooltipName {
  NSMutableString* tooltip = [NSMutableString string];
  if (_name.length > 0) {
    [tooltip appendString:_name];
    [tooltip appendString:@"\n"];
  }
  for (PHLaunchpadTopButton ix = 0; ix < PHLaunchpadTopButtonCount; ++ix) {
    NSInteger animationIndex = _layerAnimationIndex[ix];;
    if (animationIndex >= 0) {
      if (tooltip.length > 0) {
        [tooltip appendString:@"\n"];
      }
      PHAnimation* animation = _layerAnimation[ix];
      [tooltip appendString:animation.tooltipName];
    }
  }
  return tooltip;
}

- (NSArray *)categories {
  NSMutableSet* categories = [NSMutableSet set];
  for (PHLaunchpadTopButton ix = 0; ix < PHLaunchpadTopButtonCount; ++ix) {

    NSInteger animationIndex = _layerAnimationIndex[ix];;
    if (animationIndex >= 0) {
      PHAnimation* animation = _layerAnimation[ix];
      [categories addObjectsFromArray:animation.categories];
    }
  }
  [categories removeObject:PHAnimationCategoryPipes];

  return [categories allObjects];
}

@end
