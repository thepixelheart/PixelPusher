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
@class PHSystemState;
@class PHAnimation;
@class PHFMODRecorder;
@class AppDelegate;
@class PHMIDIDriver;
@class PHWallWindow;
@class PHSystem;
@class PHTooltipWindow;
@class PHOverlay;

AppDelegate* PHApp();
PHSystem* PHSys();

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (strong, readonly) PHSystem* system;

@property (strong, readonly) PHDriver* driver;
@property (strong, readonly) PHSystemState* animationDriver;
@property (strong, readonly) PHFMODRecorder* audioRecorder;
@property (strong, readonly) PHMIDIDriver* midiDriver;

// Makes a copy of all connected motes and returns them.
- (NSArray *)allMotes; // Array of PHMote

- (CGImageRef)kinectColorImage; // Must release
- (CGImageRef)kinectDepthImage; // Must release

// User things
@property (nonatomic, readonly) NSArray* gifs;
@property (nonatomic, readonly) NSDictionary* scripts; // Path => PHScript

// Called when a display link frame has completed.
- (void)didTick;

@end
