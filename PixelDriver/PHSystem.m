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

#import "AppDelegate.h"

#import "PHAnimation.h"
#import "PHSystemTick+Protected.h"

#import "PHCompositeAnimation.h"
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
NSString* const PHSystemViewStateChangedNotification = @"PHSystemViewStateChangedNotification";
NSString* const PHSystemCompositesDidChangeNotification = @"PHSystemCompositesDidChangeNotification";

@interface PHSystem() <PHDJ2GODeviceDelegate>
@end

@implementation PHSystem {
  PHSpritesheet* _pixelHeartTextSpritesheet;

  // MIDI Devices (we only support one of each)
  PHLaunchpadDevice* _launchpad;
  PHDJ2GODevice* _dj2go;

  NSInteger _numberOfLeftRotationTicks;
  NSInteger _numberOfRightRotationTicks;

  PHSystemControlIdentifier _focusedList;

  NSMutableArray* _compositeAnimations;
}

@synthesize fade = _fade;

- (id)init {
  if ((self = [super init])) {
    _faderTransition = [[PHCrossFadeTransition alloc] init];

    _compiledAnimations = [PHAnimation allAnimations];
    for (PHAnimation* animation in _compiledAnimations) {
      animation.systemState = PHApp().animationDriver;
    }

    _compositeAnimations = [@[] mutableCopy];

    _viewMode = PHViewModeLibrary;
    _launchpad = [[PHLaunchpadDevice alloc] init];
    _dj2go = [[PHDJ2GODevice alloc] init];
    _dj2go.delegate = self;

    _focusedList = PHSystemAnimations;

    _pixelHeartTextSpritesheet = [[PHSpritesheet alloc] initWithName:@"pixelhearttext"
                                                          spriteSize:CGSizeMake(42, 7)];

    NSFileManager* fm = [NSFileManager defaultManager];

    NSString* diskStorage = [self pathForDiskStorage];

    if ([fm fileExistsAtPath:diskStorage] == NO) {
      [fm createDirectoryAtPath:diskStorage withIntermediateDirectories:YES attributes:nil error:nil];
    }

    NSString *compositesPath = [self pathForCompositeFile];
    NSData *codedData = [NSData dataWithContentsOfFile:compositesPath];

    if (nil != codedData) {
      NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:codedData];
      _compositeAnimations = [[unarchiver decodeObject] mutableCopy];

      if (_compositeAnimations.count > 0) {
        _editingCompositeAnimation = _compositeAnimations[0];
      }

      [unarchiver finishDecoding];
    }
  }
  return self;
}

- (void)saveComposites {
  NSMutableData *data = [[NSMutableData alloc] init];
  NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
  [archiver encodeObject:_compositeAnimations];
  [archiver finishEncoding];

  NSString *compositesPath = [self pathForCompositeFile];
  [data writeToFile:compositesPath atomically:YES];
}

- (NSString *)pathForDiskStorage {
  NSString* userGifsPath = @"~/Library/Application Support/PixelDriver/";
  return [userGifsPath stringByExpandingTildeInPath];
}

- (NSString *)pathForCompositeFile {
  return [[self pathForDiskStorage] stringByAppendingPathComponent:@"composites.plist"];
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
  if (nil != _editingCompositeAnimation) {
    [uniqueAnimations addObject:_editingCompositeAnimation];
  }

  PHAnimationTick* leftTick = [[PHAnimationTick alloc] init];
  leftTick.numberOfRotationTicks = _numberOfLeftRotationTicks;
  PHAnimationTick* rightTick = [[PHAnimationTick alloc] init];
  rightTick.numberOfRotationTicks = _numberOfRightRotationTicks;

  _numberOfLeftRotationTicks = 0;
  _numberOfRightRotationTicks = 0;

  _leftAnimation.animationTick = leftTick;
  _rightAnimation.animationTick = rightTick;

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
  if (nil != _editingCompositeAnimation) {
    tick.editingCompositeContextRef = [[animationToContext objectForKey:[self keyForAnimation:_editingCompositeAnimation]] pointerValue];
  }

  [tick updateWallContextWithTransition:_faderTransition t:_fade];

  if (_overlayPixelHeart) {
    CGImageRef imageRef = [_pixelHeartTextSpritesheet imageAtX:0 y:0];
    CGSize textSize = _pixelHeartTextSpritesheet.spriteSize;
    CGContextDrawImage(tick.wallContextRef, CGRectMake(floorf((kWallWidth - textSize.width) / 2),
                                                       floorf((kWallHeight - textSize.height) / 2),
                                                       textSize.width, textSize.height), imageRef);
    CGImageRelease(imageRef);
  }

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
  NSString *extraNotificationName = nil;
  
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
      
    case PHSystemButtonLibrary:
      _viewMode = PHViewModeLibrary;
      extraNotificationName = PHSystemViewStateChangedNotification;
      break;
    case PHSystemButtonCompositeEditor:
      _viewMode = PHViewModeCompositeEditor;
      extraNotificationName = PHSystemViewStateChangedNotification;
      break;
    case PHSystemButtonPrefs:
      _viewMode = PHViewModePrefs;
      extraNotificationName = PHSystemViewStateChangedNotification;
      break;
      
    case PHSystemButtonNewComposite:
      break;
    case PHSystemButtonDeleteComposite:
      break;

    default:
      NSLog(@"%d is not a button", button);
      break;
  }

  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:PHSystemButtonPressedNotification object:nil userInfo:@{PHSystemIdentifierKey : [NSNumber numberWithInt:button]}];
  if (nil != extraNotificationName) {
    [nc postNotificationName:extraNotificationName object:nil];
  }
}

- (void)didReleaseButton:(PHSystemControlIdentifier)button {
  NSString *extraNotificationName = nil;
  
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
    case PHSystemButtonLibrary:
      break;
    case PHSystemButtonCompositeEditor:
      break;
    case PHSystemButtonPrefs:
      break;
    case PHSystemButtonNewComposite: {
      PHCompositeAnimation* animation = [PHCompositeAnimation animation];
      // Always immediately start editing the new animation.
      _editingCompositeAnimation = animation;
      [_compositeAnimations addObject:animation];
      extraNotificationName = PHSystemCompositesDidChangeNotification;
      [self saveComposites];
      break;
    }
    case PHSystemButtonDeleteComposite: {
      NSInteger indexOfEditingObject = [_compositeAnimations indexOfObject:_editingCompositeAnimation];
      if (indexOfEditingObject != NSNotFound) {
        [_compositeAnimations removeObject:_editingCompositeAnimation];
        if (_compositeAnimations.count > 0) {
          _editingCompositeAnimation = _compositeAnimations[MIN(_compositeAnimations.count - 1,
                                                                indexOfEditingObject)];
        } else {
          _editingCompositeAnimation = nil;
        }

        extraNotificationName = PHSystemCompositesDidChangeNotification;
        [self saveComposites];
      }
      break;
    }

    default:
      NSLog(@"%d is not a button", button);
      break;
  }

  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:PHSystemButtonReleasedNotification object:nil userInfo:@{PHSystemIdentifierKey : [NSNumber numberWithInt:button]}];
  if (nil != extraNotificationName) {
    [nc postNotificationName:extraNotificationName object:nil];
  }
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
    case PHDJ2GOKnobLeft:
      _numberOfLeftRotationTicks += ((direction == PHDJ2GODirectionCw) ? 1 : -1);
      break;
    case PHDJ2GOKnobRight:
      _numberOfRightRotationTicks += ((direction == PHDJ2GODirectionCw) ? 1 : -1);
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
    case PHDJ2GOButtonLeftHeadphones:
    case PHDJ2GOButtonRightHeadphones:
      [self didPressButton:PHSystemButtonPixelHeart];
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
    case PHDJ2GOButtonLeftHeadphones:
    case PHDJ2GOButtonRightHeadphones:
      [self didReleaseButton:PHSystemButtonPixelHeart];
      break;
    case PHDJ2GOButtonBack:
      if (_focusedList < PHSystemAnimationGroups) {
        _focusedList++;
      } else {
        _focusedList = PHSystemAnimations;
      }
      break;
    case PHDJ2GOButtonEnter:
      if (_focusedList > PHSystemAnimations) {
        _focusedList--;
      } else {
        _focusedList = PHSystemAnimationGroups;
      }
      break;

    default:
      // Do nothing.
      break;
  }
}

- (void)incrementCurrentAnimationSelection {
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:PHSystemKnobTurnedNotification object:nil userInfo:
   @{PHSystemIdentifierKey: [NSNumber numberWithInt:_focusedList],
          PHSystemValueKey: [NSNumber numberWithInt:PHSystemKnobDirectionCw]}];
}

- (void)decrementCurrentAnimationSelection {
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:PHSystemKnobTurnedNotification object:nil userInfo:
   @{PHSystemIdentifierKey: [NSNumber numberWithInt:_focusedList],
          PHSystemValueKey: [NSNumber numberWithInt:PHSystemKnobDirectionCcw]}];
}

- (NSArray *)compositeAnimations {
  return _compositeAnimations;
}

@end
