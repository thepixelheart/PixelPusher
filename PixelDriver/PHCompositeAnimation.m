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

static NSString* kNameKey = @"kNameKey";
static NSString* kVersionKey = @"kVersionKey";
static const NSInteger kVersion = 1;
const NSInteger PHNumberOfCompositeLayers = 8;

@implementation PHCompositeAnimation {
  PHAnimation* _layerAnimation[PHNumberOfCompositeLayers];
}

+ (id)animationWithLayers:(NSArray *)layers name:(NSString *)name {
  PHCompositeAnimation* animation = [super animation];
  animation->_name = [name copy];

  for (NSInteger ix = 0; ix < PHNumberOfCompositeLayers && ix < layers.count; ++ix) {
    PHAnimation* layerAnimation = layers[ix];
    animation->_layerAnimation[ix] = layerAnimation;
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
  if (_name.length > 0) {
    [description appendFormat:@"name: %@", _name];
  }
  for (NSInteger ix = 0; ix < PHNumberOfCompositeLayers; ++ix) {
    [description appendFormat:@" %@", _layerAnimation[ix]];
  }
  [description appendString:@">"];
  return description;
}

#pragma mark - NSCoding

- (id)keyForIndex:(NSInteger)ix {
  return [NSString stringWithFormat:@"%ld", ix];
}

- (id)keyForAnimationAtIndex:(NSInteger)ix {
  return [NSString stringWithFormat:@"animation.%ld", ix];
}

- (id)keyForDefiningPropertiesIndex:(NSInteger)ix {
  return [NSString stringWithFormat:@"props.%ld", ix];
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:_name forKey:kNameKey];
  [coder encodeObject:@(kVersion) forKey:kVersionKey];

  for (NSUInteger ix = 0; ix < PHNumberOfCompositeLayers; ++ix) {
    if (nil != _layerAnimation[ix]) {
      id key = [self keyForAnimationAtIndex:ix];
      [coder encodeObject:_layerAnimation[ix] forKey:key];
    }
  }
}

- (id)initWithCoder:(NSCoder *)decoder {
  if ((self = [self init])) {
    _name = [[decoder decodeObjectForKey:kNameKey] copy];

    NSNumber *versionValue = [decoder decodeObjectForKey:kVersionKey];
    NSInteger version = 0;
    if (nil != versionValue) {
      version = [versionValue intValue];
    }

    if (version == 1) {
      for (NSUInteger ix = 0; ix < PHNumberOfCompositeLayers; ++ix) {
        NSString *key = [self keyForAnimationAtIndex:ix];
        PHAnimation* animation = [decoder decodeObjectForKey:key];
        if (nil != animation) {
          _layerAnimation[ix] = animation;
        }
      }

    } else if (version == 0) {
      for (NSUInteger ix = 0; ix < PHNumberOfCompositeLayers; ++ix) {
        NSString *key = [self keyForIndex:ix];
        NSString *className = [decoder decodeObjectForKey:key];
        Class aClass = NSClassFromString(className);
        if (nil != aClass) {
          _layerAnimation[ix] = [aClass animation];

          key = [self keyForDefiningPropertiesIndex:ix];
          id definingProperties = [decoder decodeObjectForKey:key];
          _layerAnimation[ix].definingProperties = definingProperties;
        }
      }
    }
  }
  return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
  PHCompositeAnimation* animation = [[[self class] allocWithZone:zone] init];

  animation.systemState = self.systemState;
  animation->_name = [_name copyWithZone:zone];

  // Create fresh animations for this copy.
  for (NSInteger ix = 0; ix < PHNumberOfCompositeLayers; ++ix) {
    animation->_layerAnimation[ix] = [_layerAnimation[ix] copy];
  }

  return animation;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  for (NSInteger ix = 0; ix < PHNumberOfCompositeLayers; ++ix) {
    PHAnimation* animation = _layerAnimation[ix];
    if (nil != animation) {
      [animation bitmapWillStartRendering];
      [animation renderBitmapInContext:cx size:size];
      [animation bitmapDidFinishRendering];
    }
  }
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  for (NSInteger ix = 0; ix < PHNumberOfCompositeLayers; ++ix) {
    PHAnimation* animation = _layerAnimation[ix];
    if (nil != animation) {
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

- (void)setAnimation:(PHAnimation *)animation forLayer:(NSInteger)layer {
  _layerAnimation[layer] = [animation copy];
}

- (PHAnimation *)animationAtLayer:(NSInteger)layer {
  return _layerAnimation[layer];
}

- (NSArray *)layers {
  NSMutableArray *layers = [NSMutableArray array];
  for (NSInteger ix = 0; ix < PHNumberOfCompositeLayers; ++ix) {
    if (nil != _layerAnimation[ix]) {
      [layers addObject:_layerAnimation[ix]];
    } else {
      [layers addObject:@(ix)];
    }
  }
  return layers;
}

- (void)setSystemState:(PHSystemState *)driver {
  [super setSystemState:driver];

  for (NSUInteger ix = 0; ix < PHNumberOfCompositeLayers; ++ix) {
    if (nil != _layerAnimation[ix]) {
      _layerAnimation[ix].systemState = self.systemState;
    }
  }
}

- (void)setAnimationTick:(PHAnimationTick *)animationTick {
  [super setAnimationTick:animationTick];

  for (NSUInteger ix = 0; ix < PHNumberOfCompositeLayers; ++ix) {
    if (nil != _layerAnimation[ix]) {
      _layerAnimation[ix].animationTick = self.animationTick;
    }
  }
}

- (void)reset {
  for (NSInteger ix = 0; ix < PHNumberOfCompositeLayers; ++ix) {
    _layerAnimation[ix] = nil;
  }
}

- (NSString *)tooltipName {
  NSMutableString* tooltip = [NSMutableString string];
  if (_name.length > 0) {
    [tooltip appendString:_name];
    [tooltip appendString:@"\n"];
  }
  for (NSInteger ix = 0; ix < PHNumberOfCompositeLayers; ++ix) {
    if (nil != _layerAnimation[ix]) {
      if (tooltip.length > 0) {
        [tooltip appendString:@"\n"];
      }
      PHAnimation* animation = _layerAnimation[ix];
      [tooltip appendString:animation.tooltipName];
    }
  }
  if ([tooltip length] == 0) {
    [tooltip appendString:@"<New Composite>"];
  }
  return tooltip;
}

- (NSArray *)categories {
  NSMutableSet* categories = [NSMutableSet set];
  for (NSInteger ix = 0; ix < PHNumberOfCompositeLayers; ++ix) {

    PHAnimation* animation = _layerAnimation[ix];
    if (nil != animation) {
      [categories addObjectsFromArray:animation.categories];
    }
  }
  [categories removeObject:PHAnimationCategoryPipes];

  return [categories allObjects];
}

@end
