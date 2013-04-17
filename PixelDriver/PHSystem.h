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
  PHSystemButtonPixelHeart = 1000,
  PHSystemButtonLoadLeft,
  PHSystemButtonLoadRight,
  PHSystemButtonUmanoMode,
  PHSystemButtonLibrary,
  PHSystemButtonCompositeEditor,
  PHSystemButtonPrefs,
  PHSystemButtonScreenshot,
  PHSystemButtonStrobe,
  
  // Composite Editor
  PHSystemButtonNewComposite,
  PHSystemButtonDeleteComposite,
  PHSystemButtonRenameComposite,
  PHSystemButtonLoadCompositeIntoActiveLayer,
  PHSystemButtonClearCompositeActiveLayer,

  PHSystemSliderFader,

  PHSystemAnimations,
  PHSystemTransitions,
  PHSystemAnimationGroups,
  PHSystemComposites,
  PHSystemCompositeLayers,

} PHSystemControlIdentifier;

typedef enum {
  PHSystemKnobDirectionCw,
  PHSystemKnobDirectionCcw,
} PHSystemKnobDirection;

extern NSString* const PHSystemSliderMovedNotification;
extern NSString* const PHSystemKnobTurnedNotification;
extern NSString* const PHSystemButtonPressedNotification;
extern NSString* const PHSystemButtonReleasedNotification;
extern NSString* const PHSystemIdentifierKey;
extern NSString* const PHSystemValueKey;

extern NSString* const PHSystemFocusDidChangeNotification;
extern NSString* const PHSystemViewStateChangedNotification;
extern NSString* const PHSystemCompositesDidChangeNotification;
extern NSString* const PHSystemActiveCompositeDidChangeNotification;
extern NSString* const PHSystemActiveCategoryDidChangeNotification;
extern NSString* const PHSystemPreviewAnimationDidChangeNotification;

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

// The percentage fade from left to right.
@property (nonatomic, assign) CGFloat fade; // 0..1

// Actions

// When enabled displays the Pixel Heart text over the current animation.
@property (readonly, assign) BOOL overlayPixelHeart;

// When enabled displays the Pixel Heart text over the current animation.
@property (assign) BOOL umanoMode;


// Buttons

- (void)didPressButton:(PHSystemControlIdentifier)button;
- (void)didReleaseButton:(PHSystemControlIdentifier)button;

- (void)incrementCurrentAnimationSelection;
- (void)decrementCurrentAnimationSelection;

// Editor State

@property (nonatomic, assign) PHViewMode viewMode;
@property (nonatomic, readonly) NSArray* allCategories; // Sorted
@property (nonatomic, copy) NSString* activeCategory;
@property (nonatomic, readonly) NSArray* filteredAnimations;

// Ticking

// To be called at the beginning of each tick. Renders all of the active
// animation objects for the current frame. These animations are cached in the
// returned PHSystemTick object which can be used by all display link listeners
// to display the animations.
- (PHSystemTick *)tick;

@property (nonatomic, readonly, strong) PHOpenGLView* glView;
+ (CGContextRef)createWallContext;

@end
