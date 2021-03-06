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

#import <Foundation/Foundation.h>

#import "PHViewMode.h"

@class PHAnimation;
@class PHCompositeAnimation;
@class PHTransition;
@class PHSystemTick;
@class PHOpenGLView;

typedef enum {
  PHSystemDeckSpeed,
  PHSystemDeckAction1,
  PHSystemDeckAction2,

  PHSystemDeck_NumberOfControls
} PHSystemDeck;

typedef enum {
  PHSystemButtonPixelHeart = 1000,
  PHSystemButtonLoadLeft,
  PHSystemButtonLoadRight,
  PHSystemButtonSwapFaderPositions,
  PHSystemButtonUmanoMode,
  PHSystemButtonLibrary,
  PHSystemButtonCompositeEditor,
  PHSystemButtonPrefs,
  PHSystemButtonScreenshot,
  PHSystemButtonStrobe,
  PHSystemButtonOff,
  PHSystemButtonTapBPM,
  PHSystemButtonClearBPM,
  PHSystemButtonRecord,
  PHSystemButton3,
  PHSystemButton2,
  PHSystemButton1,
  PHSystemButtonText,
  PHSystemButtonFullScreen,
  
  // Composite Editor
  PHSystemButtonNewComposite,
  PHSystemButtonDeleteComposite,
  PHSystemButtonRenameComposite,
  PHSystemButtonLoadCompositeIntoActiveLayer,
  PHSystemButtonClearCompositeActiveLayer,
  
  // List Editor
  PHSystemButtonNewList,
  PHSystemButtonRenameList,
  PHSystemButtonDeleteList,

  PHSystemSliderFader,

  PHSystemVolumeMaster,

  // Left Deck
  PHSystemLeftDeckStart,
  PHSystemLeftDeckEnd = PHSystemLeftDeckStart + PHSystemDeck_NumberOfControls,

  // Right Deck
  PHSystemRightDeckStart,
  PHSystemRightDeckEnd = PHSystemRightDeckStart + PHSystemDeck_NumberOfControls,

  PHSystemAnimations,
  PHSystemTransitions,
  PHSystemAnimationLists,
  PHSystemComposites,
  PHSystemCompositeLayers,

} PHSystemControlIdentifier;

typedef enum {
  PHSystemKnobDirectionCw,
  PHSystemKnobDirectionCcw,
} PHSystemKnobDirection;

extern NSString* const PHSystemSliderMovedNotification;
extern NSString* const PHSystemKnobTurnedNotification;
extern NSString* const PHSystemVolumeChangedNotification;
extern NSString* const PHSystemButtonPressedNotification;
extern NSString* const PHSystemButtonReleasedNotification;
extern NSString* const PHSystemIdentifierKey;
extern NSString* const PHSystemValueKey;

extern NSString* const PHSystemFocusDidChangeNotification;
extern NSString* const PHSystemViewStateChangedNotification;
extern NSString* const PHSystemCompositesDidChangeNotification;
extern NSString* const PHSystemActiveCompositeDidChangeNotification;
extern NSString* const PHSystemActiveCategoryDidChangeNotification;
extern NSString* const PHSystemListsDidChangeNotification;
extern NSString* const PHSystemPreviewAnimationDidChangeNotification;
extern NSString* const PHSystemFaderDidSwapNotification;
extern NSString* const PHSystemUserScriptsDidChangeNotification;

@class PHHardwareState;

/**
 * The PHSystem class defines the global state of the Pixel Heart.
 *
 * This is a global object that must be accessed via PHSys() available from AppDelegate.h. 
 */
@interface PHSystem : NSObject

// Animations

// All compiled animations included with the PixelPusher.
@property (readonly, strong) NSArray* compiledAnimations;

// All composite animations that have been loaded from disk.
@property (readonly, strong) NSArray* compositeAnimations;

// All script animations that have been loaded from disk.
@property (readonly, strong) NSDictionary* scriptAnimations;

// Active Animations

// The animation being displayed in the left visualizer.
@property (strong) PHAnimation* leftAnimation;

// The animation being displayed in the right visualizer.
@property (strong) PHAnimation* rightAnimation;

// The animation being displayed in the preview pane for loading animations
// into the visualizer.
@property (strong) PHAnimation* previewAnimation;

// The animation being displayed in the preview pane for loading animations
// into the visualizer.
@property (strong) PHCompositeAnimation* editingCompositeAnimation;
- (void)didModifyActiveComposition;

// The current layer of the composite that is being modified.
@property (assign) NSInteger activeCompositeLayer;

// There is no PHAnimation property for the Heart because this is generated every time a tick is
// generated as a fade of the left and right animations + fade using the faderTransition.

// The transition used to fade between the left and right animations.
@property (strong) PHTransition* faderTransition;

// Controller State

// The master fade on the Heart.
@property (nonatomic, assign) CGFloat masterFade;

// The percentage fade from left to right.
@property (nonatomic, assign) CGFloat fade; // 0..1
@property (nonatomic, assign) BOOL leftAnimationIsBottom; // YES by default

- (CGFloat)bpm;
- (BOOL)isBeating;

// Actions

// When enabled displays the Pixel Heart text over the current animation.
@property (readonly, assign) BOOL overlayPixelHeart;

// When enabled, auto fades animations
@property (assign) BOOL umanoMode;

// When eneabled, the final output view is fullscreened
@property (assign) BOOL fullscreenMode;

@property (nonatomic, copy) NSString* lastScriptError;

// Decks
@property (nonatomic, readonly, strong) PHHardwareState *hardwareLeft;
@property (nonatomic, readonly, strong) PHHardwareState *hardwareRight;

// Volume

- (void)didChangeVolumeControl:(PHSystemControlIdentifier)control volume:(CGFloat)volume;

// Buttons

- (void)didPressButton:(PHSystemControlIdentifier)button;
- (void)didReleaseButton:(PHSystemControlIdentifier)button;

- (void)incrementCurrentAnimationSelection;
- (void)decrementCurrentAnimationSelection;

// Editor State

@property (nonatomic, assign) PHViewMode viewMode;
@property (nonatomic, readonly) NSArray* allLists;
@property (nonatomic, strong) id activeList;
@property (nonatomic, readonly) NSArray* filteredAnimations;
- (void)listDidChange;

// Ticking

// To be called at the beginning of each tick. Renders all of the active
// animation objects for the current frame. These animations are cached in the
// returned PHSystemTick object which can be used by all display link listeners
// to display the animations.
- (PHSystemTick *)tick;

+ (CGContextRef)createWallContext;

// Paths
- (NSString *)pathForCompositeFile;
- (NSString *)pathForScreenshots;
- (NSString *)pathForUserGifs;
- (NSString *)pathForUserScripts;
- (void)restoreDefaultComposites;

@end
