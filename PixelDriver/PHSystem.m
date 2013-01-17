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

#import "PHSystem.h"

#import "PHAnimation.h"
#import "PHDriver.h"
#import "PHCrossFadeTransition.h"

#import <objc/runtime.h>

static const char kAnimationContextKey = 0;

@interface PHSystemTick()
- (void)updateWallContextWithTransition:(PHTransition *)transition t:(CGFloat)t;
@end

@implementation PHSystem

- (id)init {
  if ((self = [super init])) {
    _faderTransition = [[PHCrossFadeTransition alloc] init];
  }
  return self;
}

+ (CGContextRef)createWallContext {
  CGSize wallSize = CGSizeMake(kWallWidth, kWallHeight);

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  if (nil == colorSpace) {
    return nil;
  }
  CGContextRef wallContext =
  CGBitmapContextCreate(NULL,
                        wallSize.width,
                        wallSize.height,
                        32,
                        0,
                        colorSpace,
                        kCGImageAlphaPremultipliedLast
                        | kCGBitmapByteOrder32Host // Necessary for intel macs.
                        | kCGBitmapFloatComponents);
  CGColorSpaceRelease(colorSpace);
  if (nil == wallContext) {
    return nil;
  }
  return wallContext;
}

- (CGContextRef)createContextFromAnimation:(PHAnimation *)animation {
  CGSize wallSize = CGSizeMake(kWallWidth, kWallHeight);
  CGRect wallFrame = CGRectMake(0, 0, wallSize.width, wallSize.height);

  CGContextRef context = [self.class createWallContext];
  CGContextClearRect(context, wallFrame);

  [animation bitmapWillStartRendering];
  [animation renderBitmapInContext:context size:wallSize];
  [animation bitmapDidFinishRendering];

  /*
  if (_isMixerButtonPressed) {
    CGImageRef imageRef = [_pixelHeartTextSpritesheet imageAtX:0 y:0];
    CGSize textSize = _pixelHeartTextSpritesheet.spriteSize;
    CGContextDrawImage(wallContext, CGRectMake(floorf((wallSize.width - textSize.width) / 2),
                                               floorf((wallSize.height - textSize.height) / 2),
                                               textSize.width, textSize.height), imageRef);
    CGImageRelease(imageRef);
  }

  [self drawOverlaysInContext:wallContext];
*/
  return context;
}

- (PHSystemTick *)tick {
  PHSystemTick* tick = [[PHSystemTick alloc] init];

  NSMutableSet* uniqueAnimations = [NSMutableSet set];
  if (nil != _leftAnimation) {
    [uniqueAnimations addObject:_leftAnimation];
  }
  if (nil != _rightAnimation) {
    [uniqueAnimations addObject:_rightAnimation];
  }
  if (nil != _previewAnimation) {
    [uniqueAnimations addObject:_previewAnimation];
  }

  for (PHAnimation* animation in uniqueAnimations) {
    CGContextRef contextRef = [self createContextFromAnimation:animation];

    objc_setAssociatedObject(animation,
                             &kAnimationContextKey,
                             [NSValue valueWithPointer:contextRef],
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }

  if (nil != _leftAnimation) {
    tick.leftContextRef = [objc_getAssociatedObject(_leftAnimation, &kAnimationContextKey) pointerValue];
  }
  if (nil != _rightAnimation) {
    tick.rightContextRef = [objc_getAssociatedObject(_rightAnimation, &kAnimationContextKey) pointerValue];
  }
  if (nil != _previewAnimation) {
    tick.previewContextRef = [objc_getAssociatedObject(_previewAnimation, &kAnimationContextKey) pointerValue];
  }

  [tick updateWallContextWithTransition:_faderTransition t:_fade];

  return tick;
}

@end

@implementation PHSystemTick

@synthesize leftContextRef = _leftContextRef;
@synthesize rightContextRef = _rightContextRef;
@synthesize previewContextRef = _previewContextRef;
@synthesize wallContextRef = _wallContextRef;

- (void)dealloc {
  if (nil != _leftContextRef) {
    CGContextRelease(_leftContextRef);
  }
  if (nil != _rightContextRef) {
    CGContextRelease(_rightContextRef);
  }
  if (nil != _previewContextRef) {
    CGContextRelease(_previewContextRef);
  }
  if (nil != _wallContextRef) {
    CGContextRelease(_wallContextRef);
  }
}

- (void)setLeftContextRef:(CGContextRef)leftContextRef {
  if (nil != _leftContextRef) {
    CGContextRelease(_leftContextRef);
  }
  _leftContextRef = CGContextRetain(leftContextRef);
}

- (void)setRightContextRef:(CGContextRef)rightContextRef {
  if (nil != _leftContextRef) {
    CGContextRelease(_rightContextRef);
  }
  _rightContextRef = CGContextRetain(rightContextRef);
}

- (void)setPreviewContextRef:(CGContextRef)previewContextRef {
  if (nil != _leftContextRef) {
    CGContextRelease(_previewContextRef);
  }
  _previewContextRef = CGContextRetain(previewContextRef);
}

- (void)setWallContextRef:(CGContextRef)wallContextRef {
  if (nil != _leftContextRef) {
    CGContextRelease(_wallContextRef);
  }
  _wallContextRef = CGContextRetain(wallContextRef);
}

- (void)updateWallContextWithTransition:(PHTransition *)transition t:(CGFloat)t {
  CGContextRef wallContext = [PHSystem createWallContext];

  CGSize wallSize = CGSizeMake(kWallWidth, kWallHeight);
  [transition renderBitmapInContext:wallContext
                               size:wallSize
                        leftContext:_leftContextRef
                       rightContext:_rightContextRef
                                  t:t];

  self.wallContextRef = wallContext;
}

@end
