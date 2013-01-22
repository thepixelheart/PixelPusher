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

#import "PHCrossFadeTransition.h"
#import "PHStarWarsTransition.h"

#import "PHLaunchpadDevice.h"
#import "PHDJ2GODevice.h"

#import <objc/runtime.h>

NSString* const PHSystemSliderMovedNotification = @"PHSystemSliderMovedNotification";
NSString* const PHSystemKnobTurnedNotification = @"PHSystemKnobTurnedNotification";
NSString* const PHSystemButtonPressedNotification = @"PHSystemButtonPressedNotification";
NSString* const PHSystemButtonReleasedNotification = @"PHSystemButtonReleasedNotification";
NSString* const PHSystemIdentifierKey = @"PHSystemIdentifierKey";
NSString* const PHSystemValueKey = @"PHSystemValueKey";

@interface PHSystemTick()
- (void)updateWallContextWithTransition:(PHTransition *)transition t:(CGFloat)t;
@end

@interface PHSystem() <PHDJ2GODeviceDelegate>
@end

@implementation PHSystem {
  PHSpritesheet* _pixelHeartTextSpritesheet;

  // MIDI Devices
  PHLaunchpadDevice* _launchpad;
  PHDJ2GODevice* _dj2go;
}

@synthesize fade = _fade;

- (id)init {
  if ((self = [super init])) {
    _faderTransition = [[PHCrossFadeTransition alloc] init];

    _launchpad = [[PHLaunchpadDevice alloc] init];
    _dj2go = [[PHDJ2GODevice alloc] init];
    _dj2go.delegate = self;

    _pixelHeartTextSpritesheet = [[PHSpritesheet alloc] initWithName:@"pixelhearttext"
                                                          spriteSize:CGSizeMake(42, 7)];
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

  if (_overlayPixelHeart) {
    CGImageRef imageRef = [_pixelHeartTextSpritesheet imageAtX:0 y:0];
    CGSize textSize = _pixelHeartTextSpritesheet.spriteSize;
    CGContextDrawImage(context, CGRectMake(floorf((wallSize.width - textSize.width) / 2),
                                           floorf((wallSize.height - textSize.height) / 2),
                                           textSize.width, textSize.height), imageRef);
    CGImageRelease(imageRef);
  }

//  [self drawOverlaysInContext:wallContext];

  return context;
}

- (id)keyForAnimation:(PHAnimation *)animation {
  return [NSString stringWithFormat:@"%lld", (unsigned long long)animation];
}

- (PHSystemTick *)tick {
  _numberOfTimesUserButton1Pressed = 0;
  _numberOfTimesUserButton2Pressed = 0;
  
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

  NSMutableDictionary* animationToContext = [NSMutableDictionary dictionary];
  for (PHAnimation* animation in uniqueAnimations) {
    CGContextRef contextRef = [self createContextFromAnimation:animation];

    [animationToContext setObject:[NSValue valueWithPointer:contextRef]
                           forKey:[self keyForAnimation:animation]];
  }

  if (nil != _leftAnimation) {
    tick.leftContextRef = [[animationToContext objectForKey:[self keyForAnimation:_leftAnimation]] pointerValue];
  }
  if (nil != _rightAnimation) {
    tick.rightContextRef = [[animationToContext objectForKey:[self keyForAnimation:_rightAnimation]] pointerValue];
  }
  if (nil != _previewAnimation) {
    tick.previewContextRef = [[animationToContext objectForKey:[self keyForAnimation:_previewAnimation]] pointerValue];
  }

  [tick updateWallContextWithTransition:_faderTransition t:_fade];

  for (NSValue* value in animationToContext.allValues) {
    CGContextRelease([value pointerValue]);
  }

  return tick;
}

#pragma mark - Button State

- (CGFloat)fade {
  return _fade;
}

- (void)setFade:(CGFloat)fade {
  _fade = fade;

  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:PHSystemSliderMovedNotification object:nil userInfo:
   @{PHSystemIdentifierKey: [NSNumber numberWithInt:PHSystemSliderFader],
          PHSystemValueKey: [NSNumber numberWithDouble:fade]}];
}

- (void)didPressButton:(PHSystemControlIdentifier)button {
  switch (button) {
    case PHSystemButtonPixelHeart:
      _overlayPixelHeart = YES;
      break;
    case PHSystemButtonUserAction1:
      _isUserButton1Pressed = YES;
      break;
    case PHSystemButtonUserAction2:
      _isUserButton2Pressed = YES;
      break;
    case PHSystemButtonLoadLeft:
      _leftAnimation = _previewAnimation;
      break;
    case PHSystemButtonLoadRight:
      _rightAnimation = _previewAnimation;
      break;

    default:
      NSLog(@"%d is not a button", button);
      break;
  }

  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:PHSystemButtonPressedNotification object:nil userInfo:@{PHSystemIdentifierKey : [NSNumber numberWithInt:button]}];
}

- (void)didReleaseButton:(PHSystemControlIdentifier)button {
  switch (button) {
    case PHSystemButtonPixelHeart:
      _overlayPixelHeart = NO;
      break;
    case PHSystemButtonUserAction1:
      _numberOfTimesUserButton1Pressed++;
      _isUserButton1Pressed = NO;
      break;
    case PHSystemButtonUserAction2:
      _numberOfTimesUserButton2Pressed++;
      _isUserButton2Pressed = NO;
      break;
    case PHSystemButtonLoadLeft:
      break;
    case PHSystemButtonLoadRight:
      break;

    default:
      NSLog(@"%d is not a button", button);
      break;
  }

  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:PHSystemButtonReleasedNotification object:nil userInfo:@{PHSystemIdentifierKey : [NSNumber numberWithInt:button]}];
}

#pragma mark - PHDJ2GODeviceDelegate

- (void)slider:(PHDJ2GOSlider)slider didChangeValue:(CGFloat)value {
  switch (slider) {
    case PHDJ2GOSliderMid:
      [self setFade:value];
      break;

    default:
      // Do nothing.
      break;
  }
}

- (void)volume:(PHDJ2GOVolume)volume didChangeValue:(CGFloat)value {

}

- (void)knob:(PHDJ2GOKnob)knob didRotate:(PHDJ2GODirection)direction {
  switch (knob) {
    case PHDJ2GOKnobBrowse:
      if (direction == PHDJ2GODirectionCw) {
        [self incrementCurrentAnimationSelection];
      } else {
        [self decrementCurrentAnimationSelection];
      }
      break;

    default:
      break;
  }
}

- (void)buttonWasPressed:(PHDJ2GOButton)button {
  switch (button) {
    case PHDJ2GOButtonLoadA:
      [self didPressButton:PHSystemButtonLoadLeft];
      break;
    case PHDJ2GOButtonLoadB:
      [self didPressButton:PHSystemButtonLoadRight];
      break;
      
    default:
      // Do nothing.
      break;
  }
}

- (void)buttonWasReleased:(PHDJ2GOButton)button {
  switch (button) {
    case PHDJ2GOButtonLoadA:
      [self didReleaseButton:PHSystemButtonLoadLeft];
      break;
    case PHDJ2GOButtonLoadB:
      [self didReleaseButton:PHSystemButtonLoadRight];
      break;

    default:
      // Do nothing.
      break;
  }
}

- (void)incrementCurrentAnimationSelection {
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:PHSystemKnobTurnedNotification object:nil userInfo:
   @{PHSystemIdentifierKey: [NSNumber numberWithInt:PHSystemAnimations],
          PHSystemValueKey: [NSNumber numberWithInt:PHSystemKnobDirectionCw]}];
}

- (void)decrementCurrentAnimationSelection {
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:PHSystemKnobTurnedNotification object:nil userInfo:
   @{PHSystemIdentifierKey: [NSNumber numberWithInt:PHSystemAnimations],
          PHSystemValueKey: [NSNumber numberWithInt:PHSystemKnobDirectionCcw]}];
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
  if (nil != _rightContextRef && _rightContextRef != _leftContextRef) {
    CGContextRelease(_rightContextRef);
  }
  if (nil != _previewContextRef && _previewContextRef != _leftContextRef && _previewContextRef != _rightContextRef) {
    CGContextRelease(_previewContextRef);
  }
  if (nil != _wallContextRef && _wallContextRef != _previewContextRef && _wallContextRef != _rightContextRef && _wallContextRef != _leftContextRef) {
    CGContextRelease(_wallContextRef);
  }
}

- (void)setLeftContextRef:(CGContextRef)leftContextRef {
  if (_leftContextRef == leftContextRef) {
    return;
  }
  if (nil != _leftContextRef) {
    CGContextRelease(_leftContextRef);
  }
  _leftContextRef = CGContextRetain(leftContextRef);
}

- (void)setRightContextRef:(CGContextRef)rightContextRef {
  if (_rightContextRef == rightContextRef) {
    return;
  }
  if (nil != _rightContextRef) {
    CGContextRelease(_rightContextRef);
  }
  _rightContextRef = CGContextRetain(rightContextRef);
}

- (void)setPreviewContextRef:(CGContextRef)previewContextRef {
  if (_previewContextRef == previewContextRef) {
    return;
  }
  if (nil != _previewContextRef) {
    CGContextRelease(_previewContextRef);
  }
  _previewContextRef = CGContextRetain(previewContextRef);
}

- (void)setWallContextRef:(CGContextRef)wallContextRef {
  if (_wallContextRef == wallContextRef) {
    return;
  }
  if (nil != _wallContextRef) {
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

  CGContextRelease(wallContext);
}

@end
