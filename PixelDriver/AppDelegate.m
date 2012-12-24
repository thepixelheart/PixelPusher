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

#import "AppDelegate.h"

#import "PHAnimation.h"
#import "PHDisplayLink.h"
#import "PHDriver.h"
#import "PHFMODRecorder.h"
#import "PHLaunchpadMIDIDriver.h"
#import "PHUSBNotifier.h"
#import "PHWallView.h"

static const NSTimeInterval kCrossFadeDuration = 1;

typedef enum {
  PHLaunchpadModeAnimations,
  PHLaunchpadModePreview,
  PHLaunchpadModeComposite,
} PHLaunchpadMode;

AppDelegate *PHApp() {
  return (AppDelegate *)[NSApplication sharedApplication].delegate;
}

@interface PHCompositeAnimation : PHAnimation <NSCopying>

- (NSInteger)indexOfAnimationForLayer:(PHLaunchpadTopButton)layer;
- (void)setAnimationIndex:(NSInteger)animationIndex forLayer:(PHLaunchpadTopButton)layer;
- (void)reset;

@end

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
  for (NSInteger ix = 0; ix < PHLaunchpadTopButtonCount; ++ix) {
    PHAnimation* animation = _layerAnimation[ix];
    if (nil != animation) {
      [animation renderBitmapInContext:cx size:size];
    }
  }
}

- (NSInteger)indexOfAnimationForLayer:(PHLaunchpadTopButton)layer {
  return _layerAnimationIndex[layer];
}

- (void)setAnimationIndex:(NSInteger)animationIndex forLayer:(PHLaunchpadTopButton)layer {
  _layerAnimationIndex[layer] = animationIndex;
  if (animationIndex >= 0) {
    NSArray* animations = [PHAnimation allAnimations];
    _layerAnimation[layer] = animations[animationIndex];
    _layerAnimation[layer].driver = self.driver;
  } else {
    _layerAnimation[layer] = nil;
  }
}

- (void)reset {
  for (NSInteger ix = 0; ix < PHLaunchpadTopButtonCount; ++ix) {
    _layerAnimationIndex[ix] = -1;
    _layerAnimation[ix] = nil;
  }
}

@end

@implementation AppDelegate {
  PHDisplayLink* _displayLink;
  PHUSBNotifier* _usbNotifier;

  NSMutableArray* _animations;
  NSMutableArray* _previewAnimations;
  NSMutableArray* _compositeAnimations;
  NSMutableArray* _previewCompositeAnimations;

  PHLaunchpadMode _launchpadMode;

  // Animation/preview top button modes
  BOOL _instantCrossfade;

  // Composite mode
  PHLaunchpadTopButton _activeCompositeLayer;
  PHCompositeAnimation* _compositeAnimationBeingEdited;
  BOOL _isConfirmingDeletion;

  PHAnimation* _activeAnimation;
  PHAnimation* _previousAnimation;
  PHAnimation* _previewAnimation;
  NSTimeInterval _crossFadeStartTime;
}

@synthesize audioRecorder = _audioRecorder;
@synthesize midiDriver = _midiDriver;

- (void)prepareWindow:(PHWallWindow *)window {
  [window setAcceptsMouseMovedEvents:YES];
  [window setMovableByWindowBackground:YES];

  NSRect frame = self.window.frame;

  CGFloat midX = NSMidX(frame);
  CGFloat midY = NSMidY(frame);

  frame.size.width = kWallWidth * window.wallView.pixelSize + (kWallWidth + 1) * kPixelBorderSize;
  frame.size.height = kWallHeight * window.wallView.pixelSize + (kWallHeight + 1) * kPixelBorderSize;
  [window setMaxSize:frame.size];
  [window setMinSize:frame.size];

  [window setFrame:NSMakeRect(floorf(midX - frame.size.width * 0.5f),
                              floorf(midY - frame.size.height * 0.5f),
                              frame.size.width,
                              frame.size.height)
                display:YES];
}

- (NSMutableArray *)createAnimations {
  NSArray* animations = [PHAnimation allAnimations];

  for (PHAnimation* animation in animations) {
    animation.driver = _animationDriver;
  }

  return [animations mutableCopy];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
  [[self audioRecorder] toggleListening];

  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self
         selector:@selector(launchpadStateDidChange:)
             name:PHLaunchpadDidReceiveStateChangeNotification
           object:nil];
  [nc addObserver:self
         selector:@selector(launchpadDidConnect:)
             name:PHLaunchpadDidConnectNotification
           object:nil];
  [nc addObserver:self
         selector:@selector(displayLinkDidFire:)
             name:PHDisplayLinkFiredNotification
           object:nil];

  self.window.wallView.pixelSize = 16;
  [self prepareWindow:self.window];
  self.previewWindow.wallView.pixelSize = 8;
  [self prepareWindow:self.previewWindow];

  [self.launchpadWindow setAcceptsMouseMovedEvents:YES];
  [self.launchpadWindow setMovableByWindowBackground:YES];

  self.window.wallView.primary = YES;

  _driver = [[PHDriver alloc] init];
  _displayLink = [[PHDisplayLink alloc] init];
  _usbNotifier = [[PHUSBNotifier alloc] init];
  [self midiDriver];

  _launchpadMode = PHLaunchpadModeAnimations;

  _animationDriver = [[PHAnimationDriver alloc] init];
  _animations = [self createAnimations];
  _previewAnimations = [self createAnimations];
  _compositeAnimations = [NSMutableArray array]; // TODO Load this from disk.
  _previewCompositeAnimations = [NSMutableArray array];
  _activeAnimation = [_animations objectAtIndex:6];
  _previewAnimation = [_animations objectAtIndex:1];
  _previousAnimation = nil;
  _activeCompositeLayer = 0;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [self.window performSelector:@selector(makeKeyAndOrderFront:) withObject:self afterDelay:0.5];
  [self.previewWindow performSelector:@selector(makeKeyAndOrderFront:) withObject:self afterDelay:0.5];
  [self.launchpadWindow performSelector:@selector(makeKeyAndOrderFront:) withObject:self afterDelay:0.5];
  [self.window center];

  [self launchpadDidConnect:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
  return YES;
}

- (PHFMODRecorder *)audioRecorder {
  if (nil == _audioRecorder) {
    _audioRecorder = [[PHFMODRecorder alloc] init];
  }
  return _audioRecorder;
}

- (PHLaunchpadMIDIDriver *)midiDriver {
  if (nil == _midiDriver) {
    _midiDriver = [[PHLaunchpadMIDIDriver alloc] init];
  }
  return _midiDriver;
}

- (NSInteger)buttonIndexOfAnimation:(PHAnimation *)animation {
  if (nil == animation) {
    return -1;
  }

  NSInteger buttonIndex = [_animations indexOfObject:animation];
  if (buttonIndex == NSNotFound) {
    buttonIndex = [_previewAnimations indexOfObject:animation];
  }
  if (buttonIndex == NSNotFound) {
    buttonIndex = [_compositeAnimations indexOfObject:animation];
    if (buttonIndex != NSNotFound) {
      buttonIndex += _animations.count;
    }
  }
  if (buttonIndex == NSNotFound) {
    buttonIndex = [_previewCompositeAnimations indexOfObject:animation];
    if (buttonIndex != NSNotFound) {
      buttonIndex += _animations.count;
    }
  }
  if (buttonIndex == NSNotFound) {
    NSLog(@"Couldn't find animation! %@", animation);
    return -1;
  }
  return buttonIndex;
}

#pragma mark - Colors

- (PHLaunchpadColor)buttonColorForButtonIndex:(NSInteger)buttonIndex {
  if (buttonIndex >= (_animations.count + _compositeAnimations.count)) {
    return PHLaunchpadColorOff;
  }

  BOOL isActiveAnimation = [self buttonIndexOfAnimation:_activeAnimation] == buttonIndex;
  BOOL isPreviousAnimation = [self buttonIndexOfAnimation:_previousAnimation] == buttonIndex;

  if (_launchpadMode == PHLaunchpadModeAnimations) {
    return (isPreviousAnimation
            ? PHLaunchpadColorGreenFlashing
            : (isActiveAnimation ? PHLaunchpadColorGreenBright : PHLaunchpadColorGreenDim));

  } else if (_launchpadMode == PHLaunchpadModePreview) {
    BOOL isPreviewAnimation = [self buttonIndexOfAnimation:_previewAnimation] == buttonIndex;
    return (isPreviousAnimation
            ? PHLaunchpadColorGreenFlashing
            : (isActiveAnimation
               ? (isPreviewAnimation
                  ? PHLaunchpadColorRedBright
                  : PHLaunchpadColorGreenBright)
               : (isPreviewAnimation
                  ? PHLaunchpadColorYellowBright
                  : PHLaunchpadColorAmberDim)));

  } else if (_launchpadMode == PHLaunchpadModeComposite
             && buttonIndex < _animations.count) {
    NSInteger activeAnimationIndex = [_compositeAnimationBeingEdited indexOfAnimationForLayer:_activeCompositeLayer];
    return (buttonIndex == activeAnimationIndex) ? PHLaunchpadColorGreenBright : PHLaunchpadColorGreenDim;
  }
  return PHLaunchpadColorOff;
}

- (PHLaunchpadColor)topButtonColorForIndex:(PHLaunchpadTopButton)buttonIndex {
  if (_launchpadMode == PHLaunchpadModeAnimations
      || _launchpadMode == PHLaunchpadModePreview) {
    if (buttonIndex == PHLaunchpadTopButtonSession && _instantCrossfade) {
      return PHLaunchpadColorGreenBright;
    } else {
      return PHLaunchpadColorOff;
    }
  } else if (_launchpadMode == PHLaunchpadModeComposite) {
    NSInteger animationIndex = [_compositeAnimationBeingEdited indexOfAnimationForLayer:buttonIndex];

    if (_activeCompositeLayer == buttonIndex) {
      return (animationIndex >= 0) ? PHLaunchpadColorGreenBright : PHLaunchpadColorAmberBright;
    } else {
      return (animationIndex >= 0) ? PHLaunchpadColorGreenDim : PHLaunchpadColorAmberDim;
    }

  } else {
    return PHLaunchpadColorOff;
  }
}

- (PHLaunchpadColor)sideButtonColorForIndex:(PHLaunchpadSideButton)buttonIndex {
  if (_launchpadMode == PHLaunchpadModeComposite) {
    if (buttonIndex == PHLaunchpadSideButtonSendA) {
      // If the composite animation is already in the set of animations then we
      // don't show a "save" button for it.
      return [_previewCompositeAnimations containsObject:_compositeAnimationBeingEdited] ? PHLaunchpadColorOff : PHLaunchpadColorGreenDim;

    } else if (buttonIndex == PHLaunchpadSideButtonSendB) {
      return _isConfirmingDeletion ? PHLaunchpadColorRedFlashing : PHLaunchpadColorRedDim;
    }
  }
  if (buttonIndex == PHLaunchpadSideButtonArm) {
    return (_launchpadMode == PHLaunchpadModePreview) ? PHLaunchpadColorGreenBright : PHLaunchpadColorAmberDim;

  } else if (buttonIndex == PHLaunchpadSideButtonTrackOn) {
    return (_launchpadMode == PHLaunchpadModeComposite) ? PHLaunchpadColorGreenBright : PHLaunchpadColorAmberDim;

  } else {
    return PHLaunchpadColorOff;
  }
}

#pragma mark - Launchpad

- (NSInteger)numberOfAnimations {
  return _animations.count + _compositeAnimations.count;
}

- (void)updateGrid {
  PHLaunchpadMIDIDriver* launchpad = PHApp().midiDriver;

  for (NSInteger ix = 0; ix < [self numberOfAnimations]; ++ix) {
    [launchpad setButtonColor:[self buttonColorForButtonIndex:ix]
                atButtonIndex:ix];
  }
}

- (void)updateTopButtons {
  PHLaunchpadMIDIDriver* launchpad = PHApp().midiDriver;
  
  for (NSInteger ix = 0; ix < PHLaunchpadTopButtonCount; ++ix) {
    [launchpad setTopButtonColor:[self topButtonColorForIndex:(PHLaunchpadTopButton)ix]
                         atIndex:ix];
  }
}

- (void)updateSideButtons {
  PHLaunchpadMIDIDriver* launchpad = PHApp().midiDriver;
  
  for (NSInteger ix = 0; ix < PHLaunchpadSideButtonCount; ++ix) {
    [launchpad setRightButtonColor:[self sideButtonColorForIndex:(PHLaunchpadSideButton)ix]
                           atIndex:ix];
  }
}

- (void)updateLaunchpad {
  [self updateGrid];
  [self updateTopButtons];
  [self updateSideButtons];
}

- (void)toggleLaunchpadMode:(PHLaunchpadMode)mode {
  if (_launchpadMode == mode) {
    _launchpadMode = PHLaunchpadModeAnimations;
  } else {
    _launchpadMode = mode;

    if (_launchpadMode == PHLaunchpadModeComposite) {
      if (nil == _compositeAnimationBeingEdited) {
        // If we're not editing one, create a default one.
        _compositeAnimationBeingEdited = [PHCompositeAnimation animation];
        _compositeAnimationBeingEdited.driver = self.animationDriver;
      }
    }
  }

  [self updateLaunchpad];
}

- (void)launchpadDidConnect:(NSNotification *)notification {
  PHLaunchpadMIDIDriver* launchpad = PHApp().midiDriver;
  [launchpad reset];
  [launchpad enableFlashing];
  [launchpad startDoubleBuffering];

  [self updateLaunchpad];

  [launchpad flipBuffer];
}

#pragma mark - Animations

- (PHAnimation *)animationFromButtonIndex:(NSInteger)buttonIndex {
  if (buttonIndex < _animations.count) {
    return [_animations objectAtIndex:buttonIndex];
  } else {
    return [_compositeAnimations objectAtIndex:buttonIndex - _animations.count];
  }
}

- (PHAnimation *)previewAnimationFromButtonIndex:(NSInteger)buttonIndex {
  if (buttonIndex < _animations.count) {
    return [_previewAnimations objectAtIndex:buttonIndex];
  } else {
    return [_previewCompositeAnimations objectAtIndex:buttonIndex - _animations.count];
  }
}

- (void)swapAnimationsAtButtonIndex:(NSInteger)buttonIndex {
  PHAnimation* previewAnimation = [self previewAnimationFromButtonIndex:buttonIndex];

  if (buttonIndex < _animations.count) {
    [_previewAnimations replaceObjectAtIndex:buttonIndex withObject:[self animationFromButtonIndex:buttonIndex]];
    [_animations replaceObjectAtIndex:buttonIndex withObject:previewAnimation];
  } else {
    NSInteger index = buttonIndex - _animations.count;
    PHAnimation* animation = [self animationFromButtonIndex:buttonIndex];
    [_previewCompositeAnimations replaceObjectAtIndex:index withObject:animation];
    [_compositeAnimations replaceObjectAtIndex:index withObject:previewAnimation];
  }
}

- (void)setActiveAnimationIndex:(NSInteger)buttonIndex {
  if (_previousAnimation == nil) {

    // Start the transition.
    _previousAnimation = _activeAnimation;
    _crossFadeStartTime = [NSDate timeIntervalSinceReferenceDate];

    NSInteger previousAnimationButtonIndex = [self buttonIndexOfAnimation:_previousAnimation];

    [self swapAnimationsAtButtonIndex:buttonIndex];

    _activeAnimation = [self animationFromButtonIndex:buttonIndex];
    _previewAnimation = [self previewAnimationFromButtonIndex:buttonIndex];

    if (_instantCrossfade) {
      [self commitTransitionAnimation];

    } else {
      PHLaunchpadMIDIDriver* launchpad = PHApp().midiDriver;
      [launchpad setButtonColor:[self buttonColorForButtonIndex:buttonIndex]
                  atButtonIndex:buttonIndex];
      [launchpad setButtonColor:[self buttonColorForButtonIndex:previousAnimationButtonIndex]
                  atButtonIndex:previousAnimationButtonIndex];
    }
  }
}

- (void)setPreviewAnimationIndex:(NSInteger)buttonIndex {
  PHAnimation* animation = [self animationFromButtonIndex:buttonIndex];
  if (animation == _activeAnimation) {
    // Switching to the active animation is redundant, so just set the preview
    // and bail out.
    _previewAnimation = animation;
    [self updateLaunchpad];
    return;
  }
  // Tapped the previewing animation again and we're not already on this animation.
  BOOL shouldChange = _previewAnimation == animation;
  _previewAnimation = animation;
  if (shouldChange) {
    [self setActiveAnimationIndex:buttonIndex];
  } else {
    [self updateLaunchpad];
  }
}

- (void)setCompositeLayerAnimationIndex:(NSInteger)animationindex {
  NSInteger currentAnimationIndex = [_compositeAnimationBeingEdited indexOfAnimationForLayer:_activeCompositeLayer];
  if (currentAnimationIndex == animationindex) {
    // Tapping the current animation removes the animation from this layer.
    animationindex = -1;
  }
  [_compositeAnimationBeingEdited setAnimationIndex:animationindex forLayer:_activeCompositeLayer];
  [self updateGrid];
  [self updateTopButtons];
}

- (void)launchpadStateDidChange:(NSNotification *)notification {
  PHLaunchpadEvent event = [[notification.userInfo objectForKey:PHLaunchpadEventTypeUserInfoKey] intValue];
  NSInteger buttonIndex = [[notification.userInfo objectForKey:PHLaunchpadButtonIndexInfoKey] intValue];
  BOOL pressed = [[notification.userInfo objectForKey:PHLaunchpadButtonPressedUserInfoKey] boolValue];

  PHLaunchpadMIDIDriver* launchpad = PHApp().midiDriver;
  if (pressed && _isConfirmingDeletion && (event != PHLaunchpadEventRightButtonState || buttonIndex != PHLaunchpadSideButtonSendB)) {
    // When confirming the deletion, tapping any other button will cancel the
    // request for deletion.
    _isConfirmingDeletion = NO;
    [launchpad setRightButtonColor:[self sideButtonColorForIndex:(PHLaunchpadSideButton)PHLaunchpadSideButtonSendB]
                           atIndex:PHLaunchpadSideButtonSendB];
    [launchpad flipBuffer];
    return;
  }

  switch (event) {
    case PHLaunchpadEventGridButtonState: {
      // We assume that the user tapped a button that isn't showing an animation.
      BOOL isInvalidButton = YES;

      // Animations and Preview mode both have show the all animations.
      // Composite mode only shows the non-composite animations.

      if (_launchpadMode == PHLaunchpadModeAnimations
          && buttonIndex < [self numberOfAnimations]) {
        if (pressed) {
          [self setActiveAnimationIndex:buttonIndex];
        }
        isInvalidButton = NO;

      } else if (_launchpadMode == PHLaunchpadModePreview
                 && buttonIndex < [self numberOfAnimations]) {
        if (pressed) {
          [self setPreviewAnimationIndex:buttonIndex];
        }
        isInvalidButton = NO;

      } else if (_launchpadMode == PHLaunchpadModeComposite
                 && buttonIndex < _animations.count) {
        if (pressed) {
          [self setCompositeLayerAnimationIndex:buttonIndex];
        }
        isInvalidButton = NO;
      }

      if (isInvalidButton) {
        [launchpad setButtonColor:pressed ? PHLaunchpadColorRedBright : PHLaunchpadColorOff atButtonIndex:buttonIndex];
      }
      break;
    }

    case PHLaunchpadEventRightButtonState:
      if (pressed) {
        if (buttonIndex == PHLaunchpadSideButtonArm) {
          [self toggleLaunchpadMode:PHLaunchpadModePreview];

        } else if (buttonIndex == PHLaunchpadSideButtonTrackOn) {
          [self toggleLaunchpadMode:PHLaunchpadModeComposite];

        } else if (_launchpadMode == PHLaunchpadModeComposite) {
          if (buttonIndex == PHLaunchpadSideButtonSendA) {
            [_compositeAnimations addObject:[_compositeAnimationBeingEdited copy]];
            [_previewCompositeAnimations addObject:_compositeAnimationBeingEdited];
            [self updateSideButtons];

          } else if (buttonIndex == PHLaunchpadSideButtonSendB) {
            // Delete/reset
            _isConfirmingDeletion = !_isConfirmingDeletion;
            if (!_isConfirmingDeletion) {
              // We've confirmed the deletion, reset the animation.
              [_compositeAnimationBeingEdited reset];
              NSInteger indexOfObject = [_previewCompositeAnimations indexOfObject:_compositeAnimationBeingEdited];
              [_compositeAnimations removeObjectAtIndex:indexOfObject];
              [_previewAnimations removeObjectAtIndex:indexOfObject];
              [self updateLaunchpad];

            } else {
              [launchpad setRightButtonColor:[self sideButtonColorForIndex:(PHLaunchpadSideButton)buttonIndex]
                                     atIndex:buttonIndex];
            }
          }
        }
      }
      break;

    case PHLaunchpadEventTopButtonState:
      if (pressed) {
        if (_launchpadMode == PHLaunchpadModeComposite) {
          PHLaunchpadTopButton previousActiveLayer = _activeCompositeLayer;

          if (previousActiveLayer != buttonIndex) {
            _activeCompositeLayer = (PHLaunchpadTopButton)buttonIndex;
            [launchpad setTopButtonColor:[self topButtonColorForIndex:(PHLaunchpadTopButton)previousActiveLayer]
                                 atIndex:previousActiveLayer];
            [launchpad setTopButtonColor:[self topButtonColorForIndex:(PHLaunchpadTopButton)_activeCompositeLayer]
                                 atIndex:_activeCompositeLayer];

            [self updateGrid];
          } else {
            [self setCompositeLayerAnimationIndex:-1];
          }

        } else if (buttonIndex == PHLaunchpadTopButtonSession
            && (_launchpadMode == PHLaunchpadModeAnimations
                || _launchpadMode == PHLaunchpadModePreview)) {
          _instantCrossfade = !_instantCrossfade;
          if (nil != _previousAnimation) {
            [self commitTransitionAnimation];
          }
          [launchpad setTopButtonColor:_instantCrossfade ? PHLaunchpadColorGreenBright : PHLaunchpadColorOff
                               atIndex:buttonIndex];
        }
      }
      break;
    default:
      break;
  }

  if (pressed) {
    [launchpad flipBuffer];
  }
}

- (PHAnimation *)previousAnimation {
  return _previousAnimation;
}

- (PHAnimation *)activeAnimation {
  return _activeAnimation;
}

- (PHAnimation *)activePreviewAnimation {
  if (_launchpadMode == PHLaunchpadModeComposite) {
    return _compositeAnimationBeingEdited;
  }
  return _previewAnimation;
}

#pragma mark - Display Link

- (void)commitTransitionAnimation {
  PHLaunchpadMIDIDriver* launchpad = PHApp().midiDriver;

  NSInteger previousAnimationButtonIndex = [self buttonIndexOfAnimation:_previousAnimation];
  _previousAnimation = nil;

  [launchpad setButtonColor:[self buttonColorForButtonIndex:previousAnimationButtonIndex]
              atButtonIndex:previousAnimationButtonIndex];

  NSInteger activeAnimationButtonIndex = [self buttonIndexOfAnimation:_activeAnimation];
  [launchpad setButtonColor:[self buttonColorForButtonIndex:activeAnimationButtonIndex]
              atButtonIndex:activeAnimationButtonIndex];
}

- (void)displayLinkDidFire:(NSNotification *)notification {
  float* spectrum = [notification.userInfo[PHDisplayLinkFiredSpectrumKey] pointerValue];
  NSInteger numberOfSpectrumValues = [notification.userInfo[PHDisplayLinkFiredNumberOfSpectrumValuesKey] longValue];
  [_animationDriver setSpectrum:spectrum numberOfValues:numberOfSpectrumValues];

  if (nil != _previousAnimation) {
    NSTimeInterval delta = [NSDate timeIntervalSinceReferenceDate] - _crossFadeStartTime;
    if (delta >= kCrossFadeDuration) {
      [self commitTransitionAnimation];
    }
  }
}

- (CGContextRef)createWallContext {
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

- (NSTimeInterval)easeInEaseOut:(NSTimeInterval)t {
  t *= 2;
  if (t < 1) {
    return 0.5 * t * t;
  }
  --t;
  return -0.5 * (t * (t - 2) - 1);
}

- (CGContextRef)currentWallContext {
  CGSize wallSize = CGSizeMake(kWallWidth, kWallHeight);
  CGRect wallFrame = CGRectMake(0, 0, wallSize.width, wallSize.height);

  CGContextRef wallContext = [self createWallContext];
  CGContextClearRect(wallContext, wallFrame);

  PHAnimation* previousAnimation = [self previousAnimation];
  PHAnimation* activeAnimation = [self activeAnimation];
  if (nil != previousAnimation) {
    CGContextRef previousContext = [self createWallContext];
    CGContextRef activeContext = [self createWallContext];
    [previousAnimation renderBitmapInContext:previousContext size:wallSize];
    [activeAnimation renderBitmapInContext:activeContext size:wallSize];

    CGImageRef previousImage = CGBitmapContextCreateImage(previousContext);
    CGImageRef activeImage = CGBitmapContextCreateImage(activeContext);

    NSTimeInterval delta = [NSDate timeIntervalSinceReferenceDate] - _crossFadeStartTime;
    CGFloat t = [self easeInEaseOut:MIN(1, delta / kCrossFadeDuration)];

    CGContextSaveGState(wallContext);
    CGContextSetAlpha(wallContext, 1 - t);
    CGContextDrawImage(wallContext, wallFrame, previousImage);
    CGContextSetAlpha(wallContext, t);
    CGContextDrawImage(wallContext, wallFrame, activeImage);
    CGContextRestoreGState(wallContext);

    CGImageRelease(previousImage);
    CGImageRelease(activeImage);
    CGContextRelease(previousContext);
    CGContextRelease(activeContext);

  } else {
    [activeAnimation renderBitmapInContext:wallContext size:wallSize];
  }

  return wallContext;
}

- (CGContextRef)previewWallContext {
  CGSize wallSize = CGSizeMake(kWallWidth, kWallHeight);
  CGRect wallFrame = CGRectMake(0, 0, wallSize.width, wallSize.height);

  CGContextRef wallContext = [self createWallContext];
  CGContextClearRect(wallContext, wallFrame);

  PHAnimation* activeAnimation = [self activePreviewAnimation];
  [activeAnimation renderBitmapInContext:wallContext size:wallSize];

  return wallContext;
}

@end
