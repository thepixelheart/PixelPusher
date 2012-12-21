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

AppDelegate *PHApp();

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet PHWallWindow* window;
@property (assign) IBOutlet PHWallWindow* previewWindow;
@property (strong, readonly) PHDriver* driver;
@property (strong, readonly) PHAnimationDriver* animationDriver;
@property (strong, readonly) PHFMODRecorder* audioRecorder;
@property (strong, readonly) PHLaunchpadMIDIDriver* midiDriver;

@property (strong, readonly) PHAnimation* previousAnimation;
@property (strong, readonly) PHAnimation* activeAnimation;

// Must be released.
- (CGContextRef)currentWallContext;
- (CGContextRef)previewWallContext;

@end
