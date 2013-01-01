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

#import <Cocoa/Cocoa.h>

@class PHDriver;
@class PHAnimationDriver;
@class PHAnimation;
@class PHFMODRecorder;
@class AppDelegate;
@class PHLaunchpadMIDIDriver;
@class PHWallWindow;
@class PHTooltipWindow;
@class PHOverlay;

AppDelegate *PHApp();

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet PHWallWindow* window;
@property (assign) IBOutlet PHWallWindow* previewWindow;
@property (assign) IBOutlet NSWindow* launchpadWindow;
@property (assign) IBOutlet PHTooltipWindow* tooltipWindow;
@property (strong, readonly) PHDriver* driver;
@property (strong, readonly) PHAnimationDriver* animationDriver;
@property (strong, readonly) PHFMODRecorder* audioRecorder;
@property (strong, readonly) PHLaunchpadMIDIDriver* midiDriver;

@property (strong, readonly) PHAnimation* previousAnimation;
@property (strong, readonly) PHAnimation* activeAnimation;

// Tooltip window
- (void)pointTooltipAtView:(NSView *)view withString:(NSString *)string;
- (void)bringTooltipForward;
- (void)hideTooltip;

// Button tooltips
- (NSString *)tooltipForButtonIndex:(NSInteger)buttonIndex;
- (NSString *)tooltipForTopButtonIndex:(NSInteger)buttonIndex;
- (NSString *)tooltipForSideButtonIndex:(NSInteger)buttonIndex;

// Must be released.
- (CGContextRef)currentWallContext;
- (CGContextRef)previewWallContext;

// Makes a copy of all connected motes and returns them.
- (NSArray *)allMotes; // Array of PHMote

// Update overlays
- (void)addOverlay:(PHOverlay *)overlay;
- (void)removeOverlay:(PHOverlay *)overlay;

// User buttons
@property (nonatomic, readonly) NSInteger numberOfTimesUserButton1Pressed;
@property (nonatomic, readonly) NSInteger numberOfTimesUserButton2Pressed;
@property (nonatomic, readonly) BOOL isUserButton1Pressed;
@property (nonatomic, readonly) BOOL isUserButton2Pressed;
@property (nonatomic, readonly) BOOL isMixerButtonPressed;

// Gifs
@property (nonatomic, readonly) NSArray* gifs;
- (NSString *)pathForUserGifs;

// Called when a display link frame has completed.
- (void)didTick;

@end
