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
#import "PHHardwareState+System.h"
#import "PHSystemTick+Protected.h"

#import "PHCompositeAnimation.h"
#import "PHScript.h"
#import "PHScriptAnimation.h"

#import "PHCrossFadeTransition.h"
#import "PHStarWarsTransition.h"

#import "PHLaunchpadDevice.h"
#import "PHDJ2GODevice.h"
#import "PHLPD8Device.h"

#import <objc/runtime.h>
#import <stdlib.h>

static const NSTimeInterval kStrobeAge = 0.3;
static const NSTimeInterval kMinGifFrameDuration = 0.1;

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
NSString* const PHSystemPreviewAnimationDidChangeNotification = @"PHSystemPreviewAnimationDidChangeNotification";
NSString* const PHSystemFaderDidSwapNotification = @"PHSystemFaderDidSwapNotification";
NSString* const PHSystemUserScriptsDidChangeNotification = @"PHSystemUserScriptsDidChangeNotification";

typedef enum {
  PHLaunchpadCompositeModeNone,
  PHLaunchpadCompositeModeLoad,
  PHLaunchpadCompositeModeEdit,
} PHLaunchpadCompositeMode;

typedef enum {
  PHUmanoModeStatusIdleLeft,
  PHUmanoModeStatusIdleRight,
  PHUmanoModeStatusFadingLeft,
  PHUmanoModeStatusFadingRight,
} PHUmanoModeStatus;

typedef enum {
  PHCountdownOverlayNone,
  PHCountdownOverlay1,
  PHCountdownOverlay2,
  PHCountdownOverlay3,
  PHCountdownOverlayText,
} PHCountdownOverlay;


static const CGFloat kFaderTickLength = 0.007874;

static const NSTimeInterval kIdleTimeMinLength = 3;
static const NSTimeInterval kIdleTimeMaxLength = 10;
static const NSTimeInterval kFadeTimeMinLength = 3;
static const NSTimeInterval kFadeTimeMaxLength = 5;

@interface PHSystem() <PHDJ2GODeviceDelegate, PHLaunchpadDeviceDelegate, PHLPD8DeviceDelegate>
@end

@implementation PHSystem {
  PHSpritesheet* _pixelHeartTextSpritesheet;

  // MIDI Devices (we only support one of each)
  PHLaunchpadDevice* _launchpad;
  PHDJ2GODevice* _dj2go;
  PHLPD8Device* _lpd8;

  PHHardwareState *_hardwareLeft;
  PHHardwareState *_hardwareRight;
  CGFloat _masterFade;

  PHSystemControlIdentifier _focusedList;
  NSArray *_filteredAnimations;
  NSInteger _animationPage;
  BOOL _isLaunchpadInputMode;
  PHLaunchpadCompositeMode _launchpadCompositeMode;
  NSInteger _selectedCompositeLayer;
  
  NSTimeInterval _timerStart;
  NSTimeInterval _idleTimeLength;
  NSTimeInterval _fadeTimeLength;
  PHUmanoModeStatus _umamoModeStatus;

  NSMutableArray* _compositeAnimations;
  NSMutableDictionary* _scriptAnimations;
  BOOL _shouldTakeScreenshot;
  BOOL _strobeOn;
  BOOL _off;
  NSTimeInterval _strobeDeathStartTime;

  PHCountdownOverlay _countdownOverlay;
  NSInteger _countdownTextIndex;

  NSMutableArray* _recordingImages;
  NSTimeInterval _lastRecordedImageTime;
}

@synthesize fade = _fade, previewAnimation = _previewAnimation;

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init {
  if ((self = [super init])) {
    _masterFade = 1;
    _leftAnimationIsBottom = YES;

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
    _scriptAnimations = [@{} mutableCopy];

    _viewMode = PHViewModeLibrary;
    _focusedList = PHSystemTransitions;

    // Hardware
    _launchpad = [[PHLaunchpadDevice alloc] init];
    _launchpad.delegate = self;
    _dj2go = [[PHDJ2GODevice alloc] init];
    _dj2go.delegate = self;
    _lpd8 = [[PHLPD8Device alloc] init];
    _lpd8.delegate = self;

    // Animations are playing by default.
    [_dj2go setButton:PHDJ2GOButtonLeftPlayPause ledStateEnabled:YES];
    [_dj2go setButton:PHDJ2GOButtonRightPlayPause ledStateEnabled:YES];

    _pixelHeartTextSpritesheet = [[PHSpritesheet alloc] initWithName:@"pixelhearttext"
                                                          spriteSize:CGSizeMake(42, 7)];

    NSFileManager* fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:[self pathForDiskStorage]] == NO) {
      [fm createDirectoryAtPath:[self pathForDiskStorage] withIntermediateDirectories:YES attributes:nil error:nil];
    }

    [self restoreDefaultCompositesOverwiteExisting:NO];
    [self loadComposites];
    [self refreshScriptAnimations];

    // Umano mode OFF
    [self setUmanoMode:FALSE];
    
    // Fullscreen OFF
    [self setFullscreenMode:FALSE];

    [self refreshLaunchpad];

    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(userScriptsDidChangeNotification:) name:PHSystemUserScriptsDidChangeNotification object:nil];
  }
  return self;
}

- (void)restoreDefaultCompositesOverwiteExisting:(BOOL)overwriteExisting {
  NSString* compositeFile = [self pathForCompositeFile];
  NSFileManager* fm = [NSFileManager defaultManager];
  if ([fm fileExistsAtPath:compositeFile] && !overwriteExisting) {
    return;
  }
  if ([fm fileExistsAtPath:compositeFile]) {
    [fm moveItemAtPath:compositeFile
                toPath:[compositeFile stringByAppendingFormat:@"%f", [NSDate timeIntervalSinceReferenceDate]]
                 error:nil];
  }
  NSString* latestCompositesPath = PHFilenameForResourcePath(@"composites-latest.plist");
  [fm copyItemAtPath:latestCompositesPath toPath:compositeFile error:nil];

  [self loadComposites];
}

- (void)restoreDefaultComposites {
  [self restoreDefaultCompositesOverwiteExisting:YES];
}

- (void)loadComposites {
  _filteredAnimations = nil;

  NSString *compositesPath = [self pathForCompositeFile];
  NSData *codedData = [NSData dataWithContentsOfFile:compositesPath];

  if (nil != codedData) {
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:codedData];
    _compositeAnimations = [[unarchiver decodeObject] mutableCopy];

    if (_compositeAnimations.count > 0) {
      _editingCompositeAnimation = _compositeAnimations[0];
    }

    [unarchiver finishDecoding];

    [self refreshLaunchpad];
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:PHSystemCompositesDidChangeNotification object:nil];
  }
}

- (void)userScriptsDidChangeNotification:(NSNotification *)notification {
  _lastScriptError = nil;
  [self refreshScriptAnimations];
}

- (void)refreshScriptAnimations {
  _filteredAnimations = nil;

  NSDictionary* scripts = [PHApp() scripts];

  NSMutableArray* animationsToRemove = [NSMutableArray arrayWithArray:[_scriptAnimations allKeys]];
  for (id key in scripts) {
    PHScript* script = scripts[key];
    PHScriptAnimation* animation = _scriptAnimations[key];
    if (nil == animation) {
      animation = [PHScriptAnimation animationWithScript:script];
      _scriptAnimations[key] = animation;
    } else {
      [animationsToRemove removeObject:key];
    }
  }

  // Remove dead animations.
  for (id key in animationsToRemove) {
    [_scriptAnimations removeObjectForKey:key];
  }

  [self refreshLaunchpad];
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
  NSString* userGifsPath = @"~/Library/Application Support/PixelPusher/";
  return [userGifsPath stringByExpandingTildeInPath];
}

- (NSString *)pathForCompositeFile {
  return [[self pathForDiskStorage] stringByAppendingPathComponent:@"composites.plist"];
}

- (NSString *)pathForScreenshots {
  return [[self pathForDiskStorage] stringByAppendingPathComponent:@"screenshots"];
}

- (NSString *)pathForUserGifs {
  return [[self pathForDiskStorage] stringByAppendingPathComponent:@"gifs"];
}

- (NSString *)pathForUserScripts {
  return [[self pathForDiskStorage] stringByAppendingPathComponent:@"scripts"];
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

- (PHAnimation *)getRandomAnimation {
  NSArray* allAnimation = [_compiledAnimations arrayByAddingObjectsFromArray:_compositeAnimations];
  allAnimation = [allAnimation filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(PHAnimation *evaluatedObject, NSDictionary *bindings) {
    return (((![evaluatedObject.categories containsObject:PHAnimationCategoryFilters]
              && ![evaluatedObject.categories containsObject:PHAnimationCategoryPipes])
             || [evaluatedObject isKindOfClass:[PHCompositeAnimation class]])
            && ![evaluatedObject.categories containsObject:PHAnimationCategoryGames]
            && !evaluatedObject.isPipeAnimation);
  }]];
  return allAnimation[arc4random_uniform(allAnimation.count)];
}

- (PHTransition *)getRandomTrasition {
  NSArray* allTransition = [PHTransition allTransitions];
  return allTransition[arc4random_uniform(allTransition.count)];
}

- (CGFloat)bpm {
  return _hardwareLeft.bpm;
}

- (BOOL)isBeating {
  return _hardwareLeft.isBeating;
}

- (void)setLastScriptError:(NSString *)lastScriptError {
  if ([NSThread currentThread] != [NSThread mainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self setLastScriptError:lastScriptError];
    });
  }
  _lastScriptError = [lastScriptError copy];
}

- (PHSystemTick *)tick {
  PHSystemTick* tick = [[PHSystemTick alloc] initWithMasterFade:_masterFade];
  
  if ([self umanoMode]) {
    switch (_umamoModeStatus) {
      case PHUmanoModeStatusFadingLeft:
      case PHUmanoModeStatusFadingRight:
        if (_umamoModeStatus == PHUmanoModeStatusFadingRight) {
          [self setFade:1 - ([NSDate timeIntervalSinceReferenceDate] - _timerStart)/_fadeTimeLength];
        } else {
          [self setFade:([NSDate timeIntervalSinceReferenceDate] - _timerStart)/_fadeTimeLength];
        }
        if ([NSDate timeIntervalSinceReferenceDate] - _timerStart > _fadeTimeLength) {
          _timerStart = [NSDate timeIntervalSinceReferenceDate];
          if (_umamoModeStatus == PHUmanoModeStatusFadingRight) {
            _umamoModeStatus = PHUmanoModeStatusIdleRight;
          } else {
            _umamoModeStatus = PHUmanoModeStatusIdleLeft;
          } 
          _idleTimeLength = arc4random_uniform(kIdleTimeMaxLength - kIdleTimeMinLength) + kIdleTimeMinLength;
          // Pick a random next transition
          _faderTransition = [self getRandomTrasition];
        }
        break;
      case PHUmanoModeStatusIdleLeft:
      case PHUmanoModeStatusIdleRight:
        if ([NSDate timeIntervalSinceReferenceDate] - _timerStart > _idleTimeLength) {
          _timerStart = [NSDate timeIntervalSinceReferenceDate];
          if (_umamoModeStatus == PHUmanoModeStatusIdleLeft) {
            _umamoModeStatus = PHUmanoModeStatusFadingRight;
            _leftAnimation = [self getRandomAnimation];
          } else {
            _umamoModeStatus = PHUmanoModeStatusFadingLeft;
            _rightAnimation = [self getRandomAnimation];
          }
          _fadeTimeLength = arc4random_uniform(kFadeTimeMaxLength - kFadeTimeMinLength) + kFadeTimeMinLength;
        }
        break;
    }
  }  

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

  [tick updateWallContextWithTransition:_faderTransition t:_fade flip:!_leftAnimationIsBottom];

  if (_off) {
    CGContextSaveGState(tick.wallContextRef);
    CGContextSetFillColorWithColor(tick.wallContextRef, [NSColor blackColor].CGColor);
    CGContextFillRect(tick.wallContextRef, CGRectMake(0, 0, kWallWidth, kWallHeight));
    CGContextRestoreGState(tick.wallContextRef);
  }

  NSTimeInterval strobeAge = [NSDate timeIntervalSinceReferenceDate] - _strobeDeathStartTime;
  if (_strobeOn || strobeAge < kStrobeAge) {
    CGContextSaveGState(tick.wallContextRef);
    if (!_strobeOn) {
      CGContextSetAlpha(tick.wallContextRef, PHEaseInEaseOut(MAX(0, 1 - strobeAge / kStrobeAge)));
    }
    CGContextSetFillColorWithColor(tick.wallContextRef, [NSColor whiteColor].CGColor);
    CGContextFillRect(tick.wallContextRef, CGRectMake(0, 0, kWallWidth, kWallHeight));
    CGContextRestoreGState(tick.wallContextRef);
  }

  if (_countdownOverlay != PHCountdownOverlayNone) {
    NSImage* countdownImage = nil;
    if (_countdownOverlay == PHCountdownOverlayText) {
      countdownImage = [NSImage imageNamed:[NSString stringWithFormat:@"text_%ld", (long)_countdownTextIndex]];
    } else {
      countdownImage = [NSImage imageNamed:[NSString stringWithFormat:@"countdown_%d", _countdownOverlay]];
    }

    if (nil != countdownImage) {
      CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)[countdownImage TIFFRepresentation], NULL);
      CGImageRef imageRef =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
      CGContextSaveGState(tick.wallContextRef);
      CGContextScaleCTM(tick.wallContextRef, 1, -1);
      CGContextTranslateCTM(tick.wallContextRef, 0, -kWallHeight);

      CGContextSetAlpha(tick.wallContextRef, 1);
      CGContextDrawImage(tick.wallContextRef, CGRectMake(0,
                                                         0,
                                                         kWallWidth, kWallHeight), imageRef);
      CGImageRelease(imageRef);

      CGContextRestoreGState(tick.wallContextRef);
    }
  }

  if (_overlayPixelHeart) {
    CGImageRef imageRef = [_pixelHeartTextSpritesheet imageAtX:0 y:0];
    CGSize textSize = _pixelHeartTextSpritesheet.spriteSize;
    CGContextSetAlpha(tick.wallContextRef, 1);
    CGContextDrawImage(tick.wallContextRef, CGRectMake(floorf((kWallWidth - textSize.width) / 2),
                                                       floorf((kWallHeight - textSize.height) / 2),
                                                       textSize.width, textSize.height), imageRef);
    CGImageRelease(imageRef);
  }

  if (_recordingImages
      && (0 == _lastRecordedImageTime
          || ([NSDate timeIntervalSinceReferenceDate] - _lastRecordedImageTime) >= kMinGifFrameDuration)) {
    CGContextRef contextRef = PHCreate8BitBitmapContextWithSize(CGSizeMake(kWallWidth, kWallHeight));
    {
      CGContextSetFillColorWithColor(contextRef, [NSColor blackColor].CGColor);
      CGContextFillRect(contextRef, CGRectMake(0, 0, kWallWidth, kWallHeight));
      CGImageRef imageRef = CGBitmapContextCreateImage(tick.wallContextRef);
      CGContextScaleCTM(contextRef, 1, -1);
      CGContextTranslateCTM(contextRef, 0, -kWallHeight);
      CGContextDrawImage(contextRef, CGRectMake(0, 0, kWallWidth, kWallHeight), imageRef);
      CGImageRelease(imageRef);
    }

    CGImageRef imageRef = CGBitmapContextCreateImage(contextRef);
    [_recordingImages addObject:[NSValue valueWithPointer:imageRef]];

    _lastRecordedImageTime = [NSDate timeIntervalSinceReferenceDate];
  }

  if (_shouldTakeScreenshot) {
    _shouldTakeScreenshot = NO;

    CGContextRef contextRef = PHCreate8BitBitmapContextWithSize(CGSizeMake(kWallWidth, kWallHeight));
    CGContextSetFillColorWithColor(contextRef, [NSColor blackColor].CGColor);
    CGContextFillRect(contextRef, CGRectMake(0, 0, kWallWidth, kWallHeight));
    CGImageRef imageRef = CGBitmapContextCreateImage(tick.wallContextRef);
    CGContextScaleCTM(contextRef, 1, -1);
    CGContextTranslateCTM(contextRef, 0, -kWallHeight);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, kWallWidth, kWallHeight), imageRef);
    CGImageRelease(imageRef);

    PHCompositeAnimation* composite = nil;
    if (_fade == 0 && [_leftAnimation isKindOfClass:[PHCompositeAnimation class]]) {
      composite = (PHCompositeAnimation *)_leftAnimation;
    } else if (_fade == 1 && [_leftAnimation isKindOfClass:[PHCompositeAnimation class]]) {
      composite = (PHCompositeAnimation *)_rightAnimation;
    }
    if (composite) {
      CGImageRef flippedImageRef = CGBitmapContextCreateImage(contextRef);
      composite.screenshot = [[NSImage alloc] initWithCGImage:flippedImageRef
                                                         size:CGSizeMake(kWallWidth, kWallHeight)];
      CGImageRelease(flippedImageRef);
      [self saveComposites];
    }

    NSString *path = [self pathForScreenshots];

    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:path] == NO) {
      [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }

    path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"screenshot_%.0f.bmp", [NSDate timeIntervalSinceReferenceDate]]];
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypeBMP, 1, NULL);
    imageRef = CGBitmapContextCreateImage(contextRef);
    CGImageDestinationAddImage(destination, imageRef, nil);
    CGImageRelease(imageRef);
    CGContextRelease(contextRef);

    if (!CGImageDestinationFinalize(destination)) {
      NSLog(@"Failed to write image to %@", path);
    }

    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:path]];

    CFRelease(destination);
  }

  if (1) {
    CGContextSaveGState(tick.wallContextRef);
    CGContextSetFillColorWithColor(tick.wallContextRef, [NSColor blackColor].CGColor);
    CGContextFillRect(tick.wallContextRef, CGRectMake(0, 0, kWallWidth, kWallHeight));

    CGContextScaleCTM(tick.wallContextRef, 1, -1);
    CGContextTranslateCTM(tick.wallContextRef, 0, -kWallHeight);

    CGImageRef colorImage = [PHApp() kinectColorImage];
    CGContextDrawImage(tick.wallContextRef, CGRectMake(0, 0, kWallWidth, kWallHeight), colorImage);
    CGImageRelease(colorImage);

    CGContextRestoreGState(tick.wallContextRef);
  }

  /*
  // Shift the pixel heart by 3 pixels
  CGContextRef contextRef = PHCreate8BitBitmapContextWithSize(CGSizeMake(kWallWidth, kWallHeight));
  {
    CGContextSetFillColorWithColor(contextRef, [NSColor blackColor].CGColor);
    CGContextFillRect(contextRef, CGRectMake(0, 0, kWallWidth, kWallHeight));
    CGImageRef imageRef = CGBitmapContextCreateImage(tick.wallContextRef);
    CGContextTranslateCTM(contextRef, 3, 0);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, kWallWidth, kWallHeight), imageRef);
    CGImageRelease(imageRef);
  }

  CGContextSaveGState(tick.wallContextRef);
  CGContextSetFillColorWithColor(tick.wallContextRef, [NSColor blackColor].CGColor);
  CGContextFillRect(tick.wallContextRef, CGRectMake(0, 0, kWallWidth, kWallHeight));
  CGContextRestoreGState(tick.wallContextRef);

  CGImageRef imageRef = CGBitmapContextCreateImage(contextRef);
  CGContextDrawImage(tick.wallContextRef, CGRectMake(0, 0, kWallWidth, kWallHeight), imageRef);
  CGImageRelease(imageRef);

  CGContextRelease(contextRef);
*/
  for (NSValue* value in animationToContext.allValues) {
    CGContextRelease([value pointerValue]);
  }

  return tick;
}

- (void)unloadRecording {
  _lastRecordedImageTime = 0;
  _recordingImages = nil;
}

- (void)finishRecording {
  if (_recordingImages.count == 0) {
    [self unloadRecording];
    return;
  }

  NSArray* recordingImages = [_recordingImages copy];
  _recordingImages = nil;

  NSString *path = [self pathForScreenshots];

  NSFileManager *fm = [NSFileManager defaultManager];
  if ([fm fileExistsAtPath:path] == NO) {
    [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
  }

  path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"animation_%.0f.gif", [NSDate timeIntervalSinceReferenceDate]]];
  CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
  CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypeGIF, [_recordingImages count], NULL);


  for (NSValue* value in recordingImages) {
    CGImageRef imageRef = [value pointerValue];
    NSDictionary *props = @{(NSString *) kCGImagePropertyGIFDictionary:
                              @{(NSString *)kCGImagePropertyGIFDelayTime:@(kMinGifFrameDuration)}};
    CGImageDestinationAddImage(destination, imageRef, (__bridge CFDictionaryRef)(props));
  }

  NSDictionary* props = @{(NSString *) kCGImagePropertyGIFDictionary:
                            @{(NSString *)kCGImagePropertyGIFLoopCount:@(0)}};
  CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)(props));

  if (!CGImageDestinationFinalize(destination)) {
    NSLog(@"Failed to write image to %@", path);
  }

  [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:path]];

  CFRelease(destination);

  for (NSValue* value in recordingImages) {
    CGImageRef imageRef = [value pointerValue];
    CGImageRelease(imageRef);
  }
  [self unloadRecording];
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


- (void)toggleFullscreen {
  [self setFullscreenMode:![self fullscreenMode]];
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:PHSystemViewStateChangedNotification object:nil userInfo:nil];
}

- (void)toggleUmanoMode {
  [PHSys() setUmanoMode:![PHSys() umanoMode]];
  if ([PHSys() umanoMode]) {
    [self setViewMode:PHViewModeUmanoMode];
    
    if ([self fade] > 0.5) {
      _umamoModeStatus = PHUmanoModeStatusIdleRight;
      [self setFade:1];
    } else {
      _umamoModeStatus = PHUmanoModeStatusIdleLeft;
      [self setFade:0];
    }
    _leftAnimation = [self getRandomAnimation];
    _rightAnimation = [self getRandomAnimation];
    _timerStart = [NSDate timeIntervalSinceReferenceDate];
  } else {
    [self setViewMode:PHViewModeLibrary];
  }
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:PHSystemViewStateChangedNotification object:nil userInfo:nil];  
}

- (void)setViewMode:(PHViewMode)viewMode {
  _viewMode = viewMode;

  [self refreshLaunchpad];

  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:PHSystemViewStateChangedNotification object:nil userInfo:nil];
}

- (NSInteger)indexOfPreviewAnimation {
  return [[self filteredAnimations] indexOfObject:_previewAnimation];
}

- (NSInteger)numberOfPages {
  return ([self filteredAnimations].count + [self numberOfButtonsPerPage] - 1) / [self numberOfButtonsPerPage];
}

- (void)updateAnimationPage {
  NSInteger previewIndex = [self indexOfPreviewAnimation];
  _animationPage = previewIndex / [self numberOfButtonsPerPage];
}

- (void)setPreviewAnimation:(PHAnimation *)previewAnimation {
  if (_previewAnimation != previewAnimation) {
    _previewAnimation = previewAnimation;

    [self updateAnimationPage];

    [self refreshGrid];
    [_launchpad flipBuffer];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:PHSystemPreviewAnimationDidChangeNotification object:nil];
  }
}

- (PHAnimation *)previewAnimation {
  return _previewAnimation;
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
      [_launchpad setSideButtonColor:[self sideButtonColorForIndex:PHLaunchpadSideButtonSendA] + 1 atIndex:PHLaunchpadSideButtonSendA];
      [_launchpad flipBuffer];
      break;
    case PHSystemButtonLoadRight:
      _rightAnimation = _previewAnimation;
      [_launchpad setSideButtonColor:[self sideButtonColorForIndex:PHLaunchpadSideButtonSendB] + 1 atIndex:PHLaunchpadSideButtonSendB];
      [_launchpad flipBuffer];
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

    case PHSystemButtonClearCompositeActiveLayer:
      [_editingCompositeAnimation setAnimation:nil
                                      forLayer:_activeCompositeLayer];
      [self didModifyActiveComposition];
      break;

    case PHSystemButtonLoadCompositeIntoActiveLayer:
      _launchpadCompositeMode = PHLaunchpadCompositeModeNone;
      [_editingCompositeAnimation setAnimation:[_previewAnimation copy]
                                      forLayer:_activeCompositeLayer];
      [self didModifyActiveComposition];
      break;

    case PHSystemButtonScreenshot:
      _shouldTakeScreenshot = YES;
      break;

    case PHSystemButtonStrobe:
      _strobeOn = YES;
      [_launchpad setSideButtonColor:[self sideButtonColorForIndex:PHLaunchpadSideButtonTrackOn] + 1 atIndex:PHLaunchpadSideButtonTrackOn];
      [_launchpad flipBuffer];
      break;

    case PHSystemButtonOff:
      _off = YES;
      [_launchpad setSideButtonColor:[self sideButtonColorForIndex:PHLaunchpadSideButtonVolume] + 1 atIndex:PHLaunchpadSideButtonVolume];
      [_launchpad flipBuffer];
      break;

    case PHSystemButtonUmanoMode:
      [self toggleUmanoMode];
      break;

    case PHSystemButtonTapBPM:
      [_launchpad setSideButtonColor:[self sideButtonColorForIndex:PHLaunchpadSideButtonArm] + 1 atIndex:PHLaunchpadSideButtonArm];
      [_hardwareLeft recordBeat];
      [_hardwareRight recordBeat];
      break;
    case PHSystemButtonClearBPM:
      [_launchpad setSideButtonColor:[self sideButtonColorForIndex:PHLaunchpadSideButtonStop] + 1 atIndex:PHLaunchpadSideButtonStop];
      [_hardwareLeft clearBpm];
      [_hardwareRight clearBpm];
      break;

    case PHSystemButton3:
      _countdownOverlay = PHCountdownOverlay3;
      break;
    case PHSystemButton2:
      _countdownOverlay = PHCountdownOverlay2;
      break;
    case PHSystemButton1:
      _countdownOverlay = PHCountdownOverlay1;
      break;
    case PHSystemButtonText:
      _countdownOverlay = PHCountdownOverlayText;
      break;
    case PHSystemButtonFullScreen:
      [self toggleFullscreen];
      break;

    case PHSystemButtonRecord:
      [self unloadRecording];
      _recordingImages = [NSMutableArray array];
      break;

    default:
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
      [_launchpad setSideButtonColor:[self sideButtonColorForIndex:PHLaunchpadSideButtonSendA] atIndex:PHLaunchpadSideButtonSendA];
      [_launchpad flipBuffer];
      break;
    case PHSystemButtonLoadRight:
      [_launchpad setSideButtonColor:[self sideButtonColorForIndex:PHLaunchpadSideButtonSendB] atIndex:PHLaunchpadSideButtonSendB];
      [_launchpad flipBuffer];
      break;
    case PHSystemButtonNewComposite: {
      PHCompositeAnimation* animation = [PHCompositeAnimation animation];
      // Always immediately start editing the new animation.
      _editingCompositeAnimation = animation;
      [_compositeAnimations addObject:animation];
      _filteredAnimations = nil;
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

    case PHSystemButtonOff:
      _off = NO;
      [_launchpad setSideButtonColor:[self sideButtonColorForIndex:PHLaunchpadSideButtonVolume] atIndex:PHLaunchpadSideButtonVolume];
      [_launchpad flipBuffer];
      break;

    case PHSystemButtonStrobe:
      _strobeOn = NO;
      _strobeDeathStartTime = [NSDate timeIntervalSinceReferenceDate];
      [_launchpad setSideButtonColor:[self sideButtonColorForIndex:PHLaunchpadSideButtonTrackOn] atIndex:PHLaunchpadSideButtonTrackOn];
      [_launchpad flipBuffer];
      break;

    case PHSystemButtonTapBPM:
      [_launchpad setSideButtonColor:[self sideButtonColorForIndex:PHLaunchpadSideButtonArm] atIndex:PHLaunchpadSideButtonArm];
      break;
    case PHSystemButtonClearBPM:
      [_launchpad setSideButtonColor:[self sideButtonColorForIndex:PHLaunchpadSideButtonStop] atIndex:PHLaunchpadSideButtonStop];
      break;

    case PHSystemButton3:
      if (_countdownOverlay == PHCountdownOverlay3) {
        _countdownOverlay = PHCountdownOverlayNone;
      }
      break;
    case PHSystemButton2:
      if (_countdownOverlay == PHCountdownOverlay2) {
        _countdownOverlay = PHCountdownOverlayNone;
      }
      break;
    case PHSystemButton1:
      if (_countdownOverlay == PHCountdownOverlay1) {
        _countdownOverlay = PHCountdownOverlayNone;
      }
      break;
    case PHSystemButtonText:
      if (_countdownOverlay == PHCountdownOverlayText) {
        _countdownOverlay = PHCountdownOverlayNone;
        _countdownTextIndex = arc4random_uniform(5);
      }
      break;

    case PHSystemButtonSwapFaderPositions:
      extraNotificationName = PHSystemFaderDidSwapNotification;
      _leftAnimationIsBottom = !_leftAnimationIsBottom;
      break;

    case PHSystemButtonRecord:
      [self finishRecording];
      break;

    default:
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
      _filteredAnimations = nil;
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
  [self refreshTopButtons];
  [_launchpad flipBuffer];
  [self saveComposites];

  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:PHSystemActiveCompositeDidChangeNotification object:nil];
}

#pragma mark - PHDJ2GODeviceDelegate

- (void)dj2go:(PHDJ2GODevice *)dj2go slider:(PHDJ2GOSlider)slider didChangeValue:(CGFloat)value {
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

- (void)dj2go:(PHDJ2GODevice *)dj2go volume:(PHDJ2GOVolume)volume didChangeValue:(CGFloat)value {
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

- (void)dj2go:(PHDJ2GODevice *)dj2go knob:(PHDJ2GOKnob)knob didRotate:(PHDJ2GODirection)direction {
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

- (void)dj2go:(PHDJ2GODevice *)dj2go buttonWasPressed:(PHDJ2GOButton)button {
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

- (void)dj2go:(PHDJ2GODevice *)dj2go buttonWasReleased:(PHDJ2GOButton)button {
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
  if (_isLaunchpadInputMode) {
    if (pressed) {
      [_hardwareLeft didPressLaunchpadButtonAtX:x y:y];
      [_hardwareRight didPressLaunchpadButtonAtX:x y:y];
    }
    [_launchpad setButtonColor:PHLaunchpadColorRedDim + pressed atX:x y:y];
    return;
  }
  if (!pressed) {
    return;
  }

  NSInteger buttonIndex = x + y * PHLaunchpadButtonGridWidth;
  NSInteger animationIndex = [self animationIndexFromButtonIndex:buttonIndex];
  if (animationIndex < [self filteredAnimations].count) {
    NSInteger previewAnimationIndex = [self indexOfPreviewAnimation];
    if (previewAnimationIndex == animationIndex) {
      // Picked the same animation.

      if (_viewMode == PHViewModeCompositeEditor) {
        if (pressed) {
          if (_launchpadCompositeMode == PHLaunchpadCompositeModeNone) {
            _launchpadCompositeMode = PHLaunchpadCompositeModeLoad;
          } else {
            _launchpadCompositeMode = PHLaunchpadCompositeModeNone;
          }
          [self refreshTopButtons];
        }

      } else if (_viewMode == PHViewModeLibrary) {
        if (pressed) {
          if (_fade <= 0.01) {
            [self didPressButton:PHSystemButtonLoadRight];
          } else if (_fade >= 1. - 0.01) {
            [self didPressButton:PHSystemButtonLoadLeft];
          }
        }
      }

    } else {
      if (pressed) {
        if (_launchpadCompositeMode != PHLaunchpadCompositeModeNone) {
          _launchpadCompositeMode = PHLaunchpadCompositeModeNone;
          [self refreshTopButtons];
        }
        [self setPreviewAnimation:[self filteredAnimations][animationIndex]];
      }
    }
  }
}

- (void)launchpad:(PHLaunchpadDevice *)launchpad topButton:(PHLaunchpadTopButton)button isPressed:(BOOL)pressed {
  if (_isLaunchpadInputMode) {
    return;
  }

  if (_launchpadCompositeMode == PHLaunchpadCompositeModeLoad) {
    if (pressed) {
      _activeCompositeLayer = button;

      [self didPressButton:PHSystemButtonLoadCompositeIntoActiveLayer];
    }
    return;
  } else if (_launchpadCompositeMode == PHLaunchpadCompositeModeEdit) {
    if (_selectedCompositeLayer < 0) {
      // Selecting the layer to edit.
      if (nil != [_editingCompositeAnimation animationAtLayer:button]) {
        if (pressed) {
          _selectedCompositeLayer = button;
          [self refreshTopButtons];
        }

      } else {
        [_launchpad setTopButtonColor:pressed ? PHLaunchpadColorRedBright : [self topButtonColorForIndex:button] atIndex:button];
        [_launchpad flipBuffer];
      }

    } else {
      // Moving/deleting the layer.
      if (pressed) {
        if (button == _selectedCompositeLayer) {
          // Deleting this composite.
          [_editingCompositeAnimation setAnimation:nil forLayer:_selectedCompositeLayer];
        } else {
          PHAnimation* animation = [_editingCompositeAnimation animationAtLayer:_selectedCompositeLayer];
          [_editingCompositeAnimation setAnimation:[_editingCompositeAnimation animationAtLayer:button] forLayer:_selectedCompositeLayer];
          [_editingCompositeAnimation setAnimation:animation forLayer:button];
        }

        _selectedCompositeLayer = -1;
        [self didModifyActiveComposition];
      }
    }
    return;
  }

  switch (button) {
    case PHLaunchpadTopButtonUpArrow: {
      [_launchpad setTopButtonColor:pressed ? PHLaunchpadColorGreenBright :PHLaunchpadColorGreenDim atIndex:button];

      if (pressed) {
        NSInteger currentIndex = [_allCategories indexOfObject:_activeCategory];
        currentIndex = (currentIndex - 1 + _allCategories.count) % _allCategories.count;
        [self setActiveCategory:_allCategories[currentIndex]];
        [self refreshTopButtonColorAtIndex:PHLaunchpadTopButtonLeftArrow];
        [self refreshTopButtonColorAtIndex:PHLaunchpadTopButtonRightArrow];
      }
      [_launchpad flipBuffer];
      break;
    }
    case PHLaunchpadTopButtonDownArrow: {
      [_launchpad setTopButtonColor:pressed ? PHLaunchpadColorGreenBright :PHLaunchpadColorGreenDim atIndex:button];

      if (pressed) {
        NSInteger currentIndex = [_allCategories indexOfObject:_activeCategory];
        currentIndex = (currentIndex + 1 + _allCategories.count) % _allCategories.count;
        [self setActiveCategory:_allCategories[currentIndex]];
        [self refreshTopButtonColorAtIndex:PHLaunchpadTopButtonLeftArrow];
        [self refreshTopButtonColorAtIndex:PHLaunchpadTopButtonRightArrow];
      }
      [_launchpad flipBuffer];
      break;
    }

    case PHLaunchpadTopButtonLeftArrow: {
      if ([self numberOfPages] > 1) {
        [_launchpad setTopButtonColor:[self topButtonColorForIndex:button] + pressed atIndex:button];
        if (pressed) {
          _animationPage = (_animationPage + 1) % [self numberOfPages];
          [self refreshGrid];
          [_launchpad flipBuffer];
        }
      }
      break;
    }
    case PHLaunchpadTopButtonRightArrow: {
      if ([self numberOfPages] > 1) {
        [_launchpad setTopButtonColor:[self topButtonColorForIndex:button] + pressed atIndex:button];
        if (pressed) {
          _animationPage = (_animationPage - 1 + [self numberOfPages]) % [self numberOfPages];
          [self refreshGrid];
          [_launchpad flipBuffer];
        }
      }
      break;
    }

    case PHLaunchpadTopButtonMixer: {
      if (pressed && _viewMode != PHViewModeCompositeEditor) {
        [self didPressButton:PHSystemButtonCompositeEditor];
      } else if (!pressed && _viewMode == PHViewModeCompositeEditor) {
        [self didReleaseButton:PHSystemButtonCompositeEditor];

      } else if (pressed && _viewMode != PHViewModeLibrary) {
        [self didPressButton:PHSystemButtonLibrary];
      } else if (!pressed && _viewMode == PHViewModeLibrary) {
        [self didReleaseButton:PHSystemButtonLibrary];
      }
      break;
    }

    default:
      break;
  }
}

- (void)launchpad:(PHLaunchpadDevice *)launchpad sideButton:(PHLaunchpadSideButton)button isPressed:(BOOL)pressed {
  if (_isLaunchpadInputMode) {
    if (pressed && button == PHLaunchpadSideButtonSolo) {
      _isLaunchpadInputMode = NO;
      [self refreshLaunchpad];
    }
    return;
  }
  switch (button) {
    case PHLaunchpadSideButtonSendA:
      if (pressed) {
        [self didPressButton:PHSystemButtonLoadLeft];
      } else {
        [self didReleaseButton:PHSystemButtonLoadLeft];
      }
      break;
    case PHLaunchpadSideButtonSendB:
      if (pressed) {
        [self didPressButton:PHSystemButtonLoadRight];
      } else {
        [self didReleaseButton:PHSystemButtonLoadRight];
      }
      break;
    case PHLaunchpadSideButtonArm:
      if (_viewMode == PHViewModeCompositeEditor) {
        if (pressed) {
          if (_launchpadCompositeMode != PHLaunchpadCompositeModeEdit) {
            _selectedCompositeLayer = -1;
            _launchpadCompositeMode = PHLaunchpadCompositeModeEdit;
          } else {
            _launchpadCompositeMode = PHLaunchpadCompositeModeNone;
          }
          [self refreshTopButtons];
          [self refreshSideButtons];
          [_launchpad flipBuffer];
        }
      } else {
        if (pressed) {
          [self didPressButton:PHSystemButtonTapBPM];
        } else {
          [self didReleaseButton:PHSystemButtonTapBPM];
        }
      }
      break;

    case PHLaunchpadSideButtonStop:
      if (pressed) {
        [self didPressButton:PHSystemButtonClearBPM];
      } else {
        [self didReleaseButton:PHSystemButtonClearBPM];
      }
      break;

    case PHLaunchpadSideButtonSolo:
      if (pressed) {
        _isLaunchpadInputMode = !_isLaunchpadInputMode;
        [self refreshLaunchpad];
      }
      break;

    case PHLaunchpadSideButtonTrackOn:
      if (pressed) {
        [self didPressButton:PHSystemButtonStrobe];
      } else {
        [self didReleaseButton:PHSystemButtonStrobe];
      }
      break;

    case PHLaunchpadSideButtonVolume:
      if (pressed) {
        [self didPressButton:PHSystemButtonOff];
      } else {
        [self didReleaseButton:PHSystemButtonOff];
      }
      break;

    default:
      break;
  }
}

#pragma mark - PHLPD8DeviceDelegate

- (void)lpd8:(PHLPD8Device *)lpd8 volume:(NSInteger)volume didChangeValue:(CGFloat)value {
  NSLog(@"Volume %ld %f", volume, value);
}

- (void)lpd8:(PHLPD8Device *)lpd8 buttonWasPressed:(NSInteger)button withVelocity:(CGFloat)velocity {
  NSLog(@"Button velocity %ld %f", button, velocity);
}

- (void)lpd8:(PHLPD8Device *)lpd8 buttonWasReleased:(NSInteger)button {
  NSLog(@"Button released %ld", button);
}

- (void)setActiveCategory:(NSString *)activeCategory {
  if (![_activeCategory isEqualToString:activeCategory]) {
    _activeCategory = [activeCategory copy];
    _filteredAnimations = nil;

    NSInteger previewIndex = [self indexOfPreviewAnimation];
    if (previewIndex == NSNotFound) {
      if ([[self filteredAnimations] count] > 0) {
        _previewAnimation = [[self filteredAnimations] objectAtIndex:0];
      }
    }
    [self updateAnimationPage];
    [self refreshGrid];
    [_launchpad flipBuffer];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:PHSystemActiveCategoryDidChangeNotification object:nil];
  }
}

- (NSArray *)allAnimations {
  NSMutableArray* allAnimations = [NSMutableArray array];
  [allAnimations addObjectsFromArray:_compiledAnimations];
  [allAnimations addObjectsFromArray:_compositeAnimations];

  NSArray* scriptAnimations = [_scriptAnimations.allValues sortedArrayUsingComparator:
                               ^NSComparisonResult(PHScriptAnimation* obj1, PHScriptAnimation* obj2) {
                                 return [obj1.script.sourceFile compare:obj2.script.sourceFile];
                               }];
  [allAnimations addObjectsFromArray:scriptAnimations];
  return allAnimations;
}

- (NSArray *)filteredAnimations {
  if (nil != _filteredAnimations) {
    return _filteredAnimations;
  }

  NSArray* allAnimations = [self allAnimations];

  NSMutableArray* filteredArray = [NSMutableArray array];
  if ([_activeCategory isEqualToString:@"All"]) {
    for (PHAnimation* animation in allAnimations) {
      if ((![animation.categories containsObject:PHAnimationCategoryPipes]
           && ![animation.categories containsObject:PHAnimationCategoryFilters])
          || [animation isKindOfClass:[PHCompositeAnimation class]]) {
        [filteredArray addObject:animation];
      }
    }

  } else {
    for (PHAnimation* animation in allAnimations) {
      if (([_activeCategory isEqualToString:PHAnimationCategoryPipes]
           || [_activeCategory isEqualToString:PHAnimationCategoryFilters])
          && [animation isKindOfClass:[PHCompositeAnimation class]]) {
        continue;
      }
      if ([animation.categories containsObject:_activeCategory]) {
        [filteredArray addObject:animation];
      }
    }
  }
  _filteredAnimations = filteredArray;
  return filteredArray;
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

- (void)refreshLaunchpad {
  [self refreshGrid];
  [self refreshTopButtons];
  [self refreshSideButtons];
  [_launchpad flipBuffer];
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

- (PHLaunchpadColor)buttonColorForAnimation:(PHAnimation *)animation pressed:(BOOL)pressed {
  if ([animation isKindOfClass:[PHCompositeAnimation class]]) {
    return pressed ? PHLaunchpadColorAmberBright : PHLaunchpadColorAmberDim;
  } else {
    return pressed ? PHLaunchpadColorGreenBright : PHLaunchpadColorGreenDim;
  }
}

- (NSInteger)numberOfButtonsPerPage {
  return PHLaunchpadButtonGridHeight * PHLaunchpadButtonGridWidth;
}

- (NSInteger)animationIndexFromButtonIndex:(NSInteger)buttonIndex {
  return _animationPage * [self numberOfButtonsPerPage] + buttonIndex;
}

- (NSInteger)buttonIndexFromAnimationIndex:(NSInteger)animationIndex {
  return animationIndex % [self numberOfButtonsPerPage];
}

- (PHLaunchpadColor)buttonColorForButtonIndex:(NSInteger)buttonIndex {
  if (_isLaunchpadInputMode) {
    return PHLaunchpadColorRedDim;
  }

  NSArray *filteredAnimations = [self filteredAnimations];
  PHLaunchpadColor color = PHLaunchpadColorOff;

  NSInteger animationIndex = [self animationIndexFromButtonIndex:buttonIndex];
  if (animationIndex < filteredAnimations.count) {
    PHAnimation* animation = filteredAnimations[animationIndex];
    color = [self buttonColorForAnimation:animation pressed:_previewAnimation == animation];
  }

  return color;
}

- (PHLaunchpadColor)topButtonColorForIndex:(PHLaunchpadTopButton)buttonIndex {
  if (_isLaunchpadInputMode) {
    return PHLaunchpadColorOff;
  }

  if (_launchpadCompositeMode == PHLaunchpadCompositeModeLoad) {
    PHAnimation* animation = [_editingCompositeAnimation animationAtLayer:buttonIndex];
    return (nil != animation) ? PHLaunchpadColorAmberBright : PHLaunchpadColorOff;

  } else if (_launchpadCompositeMode == PHLaunchpadCompositeModeEdit) {
    PHAnimation* animation = [_editingCompositeAnimation animationAtLayer:buttonIndex];
    if (nil != animation) {
      return _selectedCompositeLayer == buttonIndex ? PHLaunchpadColorAmberBright : PHLaunchpadColorAmberDim;

    } else {
      return PHLaunchpadColorOff;
    }
  }

  switch (buttonIndex) {
    case PHLaunchpadTopButtonUpArrow:
    case PHLaunchpadTopButtonDownArrow:
      return PHLaunchpadColorGreenDim;
    case PHLaunchpadTopButtonLeftArrow:
    case PHLaunchpadTopButtonRightArrow:
      return ([self numberOfPages] > 1) ? PHLaunchpadColorGreenDim : PHLaunchpadColorOff;
    case PHLaunchpadTopButtonMixer:
      return _viewMode == PHViewModeCompositeEditor ? PHLaunchpadColorGreenBright : PHLaunchpadColorGreenDim;

    default:
      break;
  }
  return PHLaunchpadColorOff;
}

- (PHLaunchpadColor)sideButtonColorForIndex:(PHLaunchpadSideButton)buttonIndex {
  if (_isLaunchpadInputMode) {
    return (buttonIndex == PHLaunchpadSideButtonSolo) ? PHLaunchpadColorRedBright: PHLaunchpadColorOff;
  }

  switch (buttonIndex) {
    case PHLaunchpadSideButtonSendA:
    case PHLaunchpadSideButtonSendB:
      return PHLaunchpadColorGreenDim;
    case PHLaunchpadSideButtonArm:
      if (_viewMode == PHViewModeCompositeEditor) {
        return _launchpadCompositeMode == PHLaunchpadCompositeModeEdit ? PHLaunchpadColorGreenBright : PHLaunchpadColorGreenDim;
      } else {
        return PHLaunchpadColorGreenDim;
      }

    case PHLaunchpadSideButtonSolo:
      return PHLaunchpadColorRedDim;

    case PHLaunchpadSideButtonVolume:
      return PHLaunchpadColorAmberDim;

    case PHLaunchpadSideButtonTrackOn:
      return PHLaunchpadColorGreenDim;

    case PHLaunchpadSideButtonStop:
      return PHLaunchpadColorRedDim;

    default:
      break;
  }
  return PHLaunchpadColorOff;
}

@end
