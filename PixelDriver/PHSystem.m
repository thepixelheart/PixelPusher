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
#import "PHHardwareState.h"
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
NSString* const PHSystemFocusDidChangeNotification = @"PHSystemFocusDidChangeNotification";
NSString* const PHSystemViewStateChangedNotification = @"PHSystemViewStateChangedNotification";
NSString* const PHSystemCompositesDidChangeNotification = @"PHSystemCompositesDidChangeNotification";
NSString* const PHSystemActiveCompositeDidChangeNotification = @"PHSystemActiveCompositeDidChangeNotification";
NSString* const PHSystemActiveCategoryDidChangeNotification = @"PHSystemActiveCategoryDidChangeNotification";

static const CGFloat kFaderTickLength = 0.007874;

@interface PHSystem() <PHDJ2GODeviceDelegate, PHLaunchpadDeviceDelegate>
@end

@implementation PHSystem {
  PHSpritesheet* _pixelHeartTextSpritesheet;

  // MIDI Devices (we only support one of each)
  PHLaunchpadDevice* _launchpad;
  PHDJ2GODevice* _dj2go;

  PHHardwareState *_hardwareLeft;
  PHHardwareState *_hardwareRight;
  CGFloat _masterFade;

  PHSystemControlIdentifier _focusedList;

  NSMutableArray* _compositeAnimations;
  BOOL _tookScreenshot;
}

@synthesize fade = _fade;

- (id)init {
  if ((self = [super init])) {
    _masterFade = 1;

    NSMutableArray* categories = [[[PHAnimation allCategories] sortedArrayUsingComparator:
                                   ^NSComparisonResult(NSString* obj1, NSString* obj2) {
                                     return [obj1 compare:obj2 ];
                                   }] mutableCopy];
    [categories insertObject:@"All" atIndex:0];
    _allCategories = categories;
    _activeCategory = @"All";

    _faderTransition = [[PHCrossFadeTransition alloc] init];
    _hardwareLeft = [[PHHardwareState alloc] init];
    _hardwareRight = [[PHHardwareState alloc] init];

    _compiledAnimations = [PHAnimation allAnimations];
    for (PHAnimation* animation in _compiledAnimations) {
      animation.systemState = PHApp().animationDriver;
    }

    _compositeAnimations = [@[] mutableCopy];

    _viewMode = PHViewModeLibrary;
    _focusedList = PHSystemAnimations;

    // Hardware
    _launchpad = [[PHLaunchpadDevice alloc] init];
    _launchpad.delegate = self;
    _dj2go = [[PHDJ2GODevice alloc] init];
    _dj2go.delegate = self;

    // Animations are playing by default.
    [_dj2go setButton:PHDJ2GOButtonLeftPlayPause ledStateEnabled:YES];
    [_dj2go setButton:PHDJ2GOButtonRightPlayPause ledStateEnabled:YES];

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

    [self launchpadStateDidChange];
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

+ (CGContextRef)createRenderContext {
  CGSize wallSize = CGSizeMake(kWallWidth * 2, kWallHeight * 2);

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

  CGContextRef context = [self.class createRenderContext];
  CGContextClearRect(context, wallFrame);
  CGContextTranslateCTM(context, kWallWidth / 2, kWallHeight / 2);

  [animation bitmapWillStartRendering];
  [animation renderBitmapInContext:context size:wallSize];
  [animation bitmapDidFinishRendering];

  CGContextRef wallContext = [self.class createWallContext];
  CGImageRef imageRef = CGBitmapContextCreateImage(context);
  CGContextDrawImage(wallContext, CGRectMake(-kWallWidth / 2, -kWallHeight / 2, kWallWidth * 2, kWallHeight * 2), imageRef);
  CGImageRelease(imageRef);
  CGContextRelease(context);

//  [self drawOverlaysInContext:wallContext];

  return wallContext;
}

- (id)keyForAnimation:(PHAnimation *)animation {
  return [NSString stringWithFormat:@"%lld", (unsigned long long)animation];
}

- (PHSystemTick *)tick {
  PHSystemTick* tick = [[PHSystemTick alloc] initWithMasterFade:_masterFade];

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
  leftTick.hardwareState = _hardwareLeft;
  PHAnimationTick* rightTick = [[PHAnimationTick alloc] init];
  rightTick.hardwareState = _hardwareRight;

  [_hardwareLeft tick];
  [_hardwareRight tick];

  _editingCompositeAnimation.animationTick = [[PHAnimationTick alloc] init];
  _previewAnimation.animationTick = [[PHAnimationTick alloc] init];
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
    CGContextSetAlpha(tick.wallContextRef, 1);
    CGContextDrawImage(tick.wallContextRef, CGRectMake(floorf((kWallWidth - textSize.width) / 2),
                                                       floorf((kWallHeight - textSize.height) / 2),
                                                       textSize.width, textSize.height), imageRef);
    CGImageRelease(imageRef);
  }

  // TODO: Implement screenshot button.
  if (0) {
    if (!_tookScreenshot) {
      _tookScreenshot = YES;

      CGContextRef contextRef = PHCreate8BitBitmapContextWithSize(CGSizeMake(kWallWidth, kWallHeight));
      CGContextSetFillColorWithColor(contextRef, [NSColor blackColor].CGColor);
      CGContextFillRect(contextRef, CGRectMake(0, 0, kWallWidth, kWallHeight));
      CGImageRef imageRef = CGBitmapContextCreateImage(tick.wallContextRef);
      CGContextDrawImage(contextRef, CGRectMake(0, 0, kWallWidth, kWallHeight), imageRef);
      CGImageRelease(imageRef);

      NSString *path = [self pathForDiskStorage];
      path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"screenshot_%.0f", [NSDate timeIntervalSinceReferenceDate]]];
      CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
      CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypeBMP, 1, NULL);
      imageRef = CGBitmapContextCreateImage(contextRef);
      CGImageDestinationAddImage(destination, imageRef, nil);
      CGImageRelease(imageRef);
      CGContextRelease(contextRef);

      if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", path);
      }

      CFRelease(destination);
    }
  } else {
    _tookScreenshot = NO;
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

- (void)setViewMode:(PHViewMode)viewMode {
  _viewMode = viewMode;

  [self launchpadStateDidChange];

  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:PHSystemViewStateChangedNotification object:nil userInfo:nil];
}

- (void)didPressButton:(PHSystemControlIdentifier)button {
  NSString *extraNotificationName = nil;
  
  switch (button) {
    case PHSystemButtonPixelHeart:
      _overlayPixelHeart = YES;
      [_dj2go setButton:PHDJ2GOButtonLeftHeadphones ledStateEnabled:YES];
      [_dj2go setButton:PHDJ2GOButtonRightHeadphones ledStateEnabled:YES];
      break;

    case PHSystemButtonLoadLeft:
      _leftAnimation = _previewAnimation;
      break;
    case PHSystemButtonLoadRight:
      _rightAnimation = _previewAnimation;
      break;
      
    case PHSystemButtonLibrary:
      [self setViewMode:PHViewModeLibrary];
      break;
    case PHSystemButtonCompositeEditor:
      [self setViewMode:PHViewModeCompositeEditor];
      break;
    case PHSystemButtonPrefs:
      [self setViewMode:PHViewModePrefs];
      break;
      
    case PHSystemButtonNewComposite:
      break;
    case PHSystemButtonDeleteComposite:
      break;
    case PHSystemButtonRenameComposite:
      break;

    case PHSystemButtonClearCompositeActiveLayer:
      [_editingCompositeAnimation setAnimation:nil
                                      forLayer:_activeCompositeLayer];
      [self didModifyActiveComposition];
      break;

    case PHSystemButtonLoadCompositeIntoActiveLayer:
      [_editingCompositeAnimation setAnimation:[_previewAnimation copy]
                                      forLayer:_activeCompositeLayer];
      [self didModifyActiveComposition];
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
      [_dj2go setButton:PHDJ2GOButtonLeftHeadphones ledStateEnabled:NO];
      [_dj2go setButton:PHDJ2GOButtonRightHeadphones ledStateEnabled:NO];
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
      if (nil != _editingCompositeAnimation) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert setMessageText:@"You're about to delete a composite."];
        [alert addButtonWithTitle:@"Cancel"];
        [alert addButtonWithTitle:@"Kill it dead"];

        [alert beginSheetModalForWindow:nil
                          modalDelegate:self
                         didEndSelector:@selector(didEndDeleteAlert:returnCode:contextInfo:)
                            contextInfo:nil];
      }
      break;
    }
    case PHSystemButtonRenameComposite: {
      if (nil != _editingCompositeAnimation) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setAlertStyle:NSInformationalAlertStyle];
        [alert setMessageText:@"What'cha callin' it?"];
        NSTextView *textView = [[NSTextView alloc] init];
        textView.frame = CGRectMake(0, 0, 200, 100);
        if (nil != _editingCompositeAnimation.name) {
          textView.string = _editingCompositeAnimation.name;
        }
        [alert setAccessoryView:textView];

        [alert beginSheetModalForWindow:nil
                          modalDelegate:self
                         didEndSelector:@selector(didEndRenamingAlert:)
                            contextInfo:nil];
      }
      break;
    }

    case PHSystemButtonLoadCompositeIntoActiveLayer:
      break;

    case PHSystemButtonClearCompositeActiveLayer:
      break;

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

- (void)didEndDeleteAlert:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
  if (returnCode == NSAlertSecondButtonReturn) {
    NSInteger indexOfEditingObject = [_compositeAnimations indexOfObject:_editingCompositeAnimation];
    if (indexOfEditingObject != NSNotFound) {
      [_compositeAnimations removeObject:_editingCompositeAnimation];
      if (_compositeAnimations.count > 0) {
        _editingCompositeAnimation = _compositeAnimations[MIN(_compositeAnimations.count - 1,
                                                              indexOfEditingObject)];
      } else {
        _editingCompositeAnimation = nil;
      }

      [self saveComposites];

      NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
      [nc postNotificationName:PHSystemCompositesDidChangeNotification object:nil];
    }
  }
}

- (void)didEndRenamingAlert:(NSAlert *)alert {
  NSTextView *textView = (NSTextView *)alert.accessoryView;
  NSString *compositeName = textView.string;
  _editingCompositeAnimation.name = compositeName;
  [self saveComposites];

  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:PHSystemCompositesDidChangeNotification object:nil];
}

- (void)didModifyActiveComposition {
  [self saveComposites];

  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:PHSystemActiveCompositeDidChangeNotification object:nil];
}

#pragma mark - PHDJ2GODeviceDelegate

- (void)slider:(PHDJ2GOSlider)slider didChangeValue:(CGFloat)value {
  switch (slider) {
    case PHDJ2GOSliderMid:
      [self setFade:value];
      break;

    case PHDJ2GOSliderLeft:
      // It seems that the mid-point value overshoots the midway point by
      // one half of an tick length, so we compensate for that here.
      _hardwareLeft.fader = MAX(-0.5, MIN(0.5, (value - kFaderTickLength / 2) - 0.5));
      break;

    case PHDJ2GOSliderRight:
      _hardwareRight.fader = MAX(-0.5, MIN(0.5, (value - kFaderTickLength / 2) - 0.5));
      break;

    default:
      // Do nothing.
      break;
  }
}

- (void)volume:(PHDJ2GOVolume)volume didChangeValue:(CGFloat)value {
  switch (volume) {
    case PHDJ2GOVolumeA:
      _hardwareLeft.volume = value;
      break;
    case PHDJ2GOVolumeB:
      _hardwareRight.volume = value;
      break;
    case PHDJ2GOVolumeMaster:
      _masterFade = value;
      break;

    default:
      break;
  }
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
      _hardwareLeft.numberOfRotationTicks += ((direction == PHDJ2GODirectionCw) ? 1 : -1);
      break;
    case PHDJ2GOKnobRight:
      _hardwareRight.numberOfRotationTicks += ((direction == PHDJ2GODirectionCw) ? 1 : -1);
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

    case PHDJ2GOButtonLeftPlayPause:
      _hardwareLeft.playing = !_hardwareLeft.playing;
      [_dj2go setButton:button ledStateEnabled:_hardwareLeft.playing];
      break;
    case PHDJ2GOButtonRightPlayPause:
      _hardwareRight.playing = !_hardwareRight.playing;
      [_dj2go setButton:button ledStateEnabled:_hardwareRight.playing];
      break;

    case PHDJ2GOButtonLeftCue:
      _hardwareLeft.isUserButton1Pressed = YES;
      [_dj2go setButton:button ledStateEnabled:YES];
      break;
    case PHDJ2GOButtonRightCue:
      _hardwareRight.isUserButton1Pressed = YES;
      [_dj2go setButton:button ledStateEnabled:YES];
      break;

    case PHDJ2GOButtonLeftSync:
      _hardwareLeft.isUserButton2Pressed = YES;
      [_dj2go setButton:button ledStateEnabled:YES];
      break;
    case PHDJ2GOButtonRightSync:
      _hardwareRight.isUserButton2Pressed = YES;
      [_dj2go setButton:button ledStateEnabled:YES];
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
    case PHDJ2GOButtonEnter:
      if (_focusedList < PHSystemCompositeLayers) {
        _focusedList++;
      } else {
        _focusedList = PHSystemAnimations;
      }
      [self updateFocus];
      break;
    case PHDJ2GOButtonBack:
      if (_focusedList > PHSystemAnimations) {
        _focusedList--;
      } else {
        _focusedList = PHSystemCompositeLayers;
      }
      [self updateFocus];
      break;

    case PHDJ2GOButtonLeftCue:
      _hardwareLeft.isUserButton1Pressed = NO;
      [_dj2go setButton:button ledStateEnabled:NO];
      break;
    case PHDJ2GOButtonRightCue:
      _hardwareRight.isUserButton1Pressed = NO;
      [_dj2go setButton:button ledStateEnabled:NO];
      break;

    case PHDJ2GOButtonLeftSync:
      _hardwareLeft.isUserButton2Pressed = NO;
      [_dj2go setButton:button ledStateEnabled:NO];
      break;
    case PHDJ2GOButtonRightSync:
      _hardwareRight.isUserButton2Pressed = NO;
      [_dj2go setButton:button ledStateEnabled:NO];
      break;

    default:
      // Do nothing.
      break;
  }
}

#pragma mark - PHLaunchpadDeviceDelegate

- (void)launchpad:(PHLaunchpadDevice *)launchpad buttonAtX:(NSInteger)x y:(NSInteger)y isPressed:(BOOL)pressed {

}

- (void)launchpad:(PHLaunchpadDevice *)launchpad topButton:(PHLaunchpadTopButton)button isPressed:(BOOL)pressed {
  switch (button) {
    case PHLaunchpadTopButtonUpArrow: {
      if (pressed) {
        NSInteger currentIndex = [_allCategories indexOfObject:_activeCategory];
        currentIndex = (currentIndex - 1 + _allCategories.count) % _allCategories.count;
        [self setActiveCategory:_allCategories[currentIndex]];
      }

      [_launchpad setTopButtonColor:pressed ? PHLaunchpadColorGreenBright :PHLaunchpadColorGreenDim atIndex:button];
      break;
    }
    case PHLaunchpadTopButtonDownArrow: {
      if (pressed) {
        NSInteger currentIndex = [_allCategories indexOfObject:_activeCategory];
        currentIndex = (currentIndex + 1 + _allCategories.count) % _allCategories.count;
        [self setActiveCategory:_allCategories[currentIndex]];
      }

      [_launchpad setTopButtonColor:pressed ? PHLaunchpadColorGreenBright :PHLaunchpadColorGreenDim atIndex:button];
      break;
    }

    default:
      break;
  }
}

- (void)launchpad:(PHLaunchpadDevice *)launchpad sideButton:(PHLaunchpadSideButton)button isPressed:(BOOL)pressed {

}

- (void)setActiveCategory:(NSString *)activeCategory {
  if (![_activeCategory isEqualToString:activeCategory]) {
    _activeCategory = [activeCategory copy];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:PHSystemActiveCategoryDidChangeNotification object:nil];
  }
}

- (void)updateFocus {
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  if ((_focusedList == PHSystemComposites || _focusedList == PHSystemCompositeLayers)
      && _viewMode != PHViewModeCompositeEditor) {
    [self setViewMode:PHViewModeCompositeEditor];
  }
  [nc postNotificationName:PHSystemFocusDidChangeNotification object:nil userInfo:
   @{PHSystemIdentifierKey: [NSNumber numberWithInt:_focusedList]}];
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

- (void)launchpadStateDidChange {
  [self refreshLaunchpad];
}

- (void)refreshLaunchpad {
  [self refreshGrid];
  [self refreshTopButtons];
  [self refreshSideButtons];
}

- (void)refreshGrid {
  for (NSInteger ix = 0; ix < PHLaunchpadButtonGridWidth * PHLaunchpadButtonGridHeight; ++ix) {
    [self refreshButtonColorAtIndex:ix];
  }
}

- (void)refreshTopButtons {
  for (NSInteger ix = 0; ix < PHLaunchpadTopButtonCount; ++ix) {
    [self refreshTopButtonColorAtIndex:(PHLaunchpadTopButton)ix];
  }
}

- (void)refreshSideButtons {
  for (NSInteger ix = 0; ix < PHLaunchpadSideButtonCount; ++ix) {
    [self refreshSideButtonColorAtIndex:(PHLaunchpadSideButton)ix];
  }
}

- (void)refreshButtonColorAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex >= 0 && buttonIndex < 64) {
    [_launchpad setButtonColor:[self buttonColorForButtonIndex:buttonIndex]
                 atButtonIndex:buttonIndex];
  }
}

- (void)refreshTopButtonColorAtIndex:(PHLaunchpadTopButton)buttonIndex {
  if (buttonIndex < PHLaunchpadTopButtonCount) {
    [_launchpad setTopButtonColor:[self topButtonColorForIndex:buttonIndex]
                         atIndex:buttonIndex];
  }
}

- (void)refreshSideButtonColorAtIndex:(PHLaunchpadSideButton)buttonIndex {
  if (buttonIndex < PHLaunchpadSideButtonCount) {
    [_launchpad setSideButtonColor:[self sideButtonColorForIndex:buttonIndex]
                           atIndex:buttonIndex];
  }
}

- (PHLaunchpadColor)buttonColorForButtonIndex:(NSInteger)buttonIndex {
  return _viewMode == PHViewModeCompositeEditor ? PHLaunchpadColorGreenBright : PHLaunchpadColorRedBright;
}

- (PHLaunchpadColor)topButtonColorForIndex:(PHLaunchpadTopButton)buttonIndex {
  switch (buttonIndex) {
    case PHLaunchpadTopButtonUpArrow:
    case PHLaunchpadTopButtonDownArrow:
      return PHLaunchpadColorGreenDim;

    default:
      break;
  }
  return PHLaunchpadColorOff;
}

- (PHLaunchpadColor)sideButtonColorForIndex:(PHLaunchpadSideButton)buttonIndex {
  return PHLaunchpadColorOff;
}

@end
