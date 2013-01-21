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

@class PHAnimation;
@class PHTransition;
@class PHSystemTick;

typedef enum {
  PHSystemButtonPixelHeart = 1000,
  PHSystemButtonUserAction1,
  PHSystemButtonUserAction2,
} PHSystemButton;

extern NSString* const PHButtonPressedNotification;
extern NSString* const PHButtonReleasedNotification;
extern NSString* const PHButtonIdentifierKey;

@interface PHSystem : NSObject

// Active Animations

// The animation being displayed in the left visualizer.
@property (strong) PHAnimation* leftAnimation;

// The animation being displayed in the right visualizer.
@property (strong) PHAnimation* rightAnimation;

// The animation being displayed in the preview pane for loading animations
// into the visualizer.
@property (strong) PHAnimation* previewAnimation;

// The transition used to fade between the left and right animations.
@property (strong) PHTransition* faderTransition;

// Controller State

// The percentage fade from left to right.
@property (assign) CGFloat fade; // 0..1

// Actions

@property (readonly, assign) BOOL overlayPixelHeart;

// Buttons

- (void)didPressButton:(PHSystemButton)button;
- (void)didReleaseButton:(PHSystemButton)button;

// Ticking

// To be called at the beginning of each tick. Renders all of the active
// animation objects for the current frame. These animations are cached in the
// returned PHSystemTick object which can be used by all display link listeners
// to display the animations.
- (PHSystemTick *)tick;

@end

@interface PHSystemTick : NSObject
@property (nonatomic, assign) CGContextRef leftContextRef;
@property (nonatomic, assign) CGContextRef rightContextRef;
@property (nonatomic, assign) CGContextRef previewContextRef;
@property (nonatomic, assign) CGContextRef wallContextRef;
@end
