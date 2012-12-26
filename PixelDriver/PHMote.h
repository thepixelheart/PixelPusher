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

#import <Foundation/Foundation.h>

@class PHMoteState;

/**
 * The state of a single PixelMote 
 */
@interface PHMote : NSObject

- (id)initWithIdentifier:(NSString *)identifier stream:(NSStream *)stream;

@property (nonatomic, readonly, copy) NSString* identifier;

@property (nonatomic, copy) NSString* name;

@property (nonatomic, readonly, copy) NSArray* statesSinceLastFrame;

// Composite information in case you don't need all of the state information.
@property (nonatomic, assign) CGFloat joystickDegrees;// [0 - 360), 0 being at 3 o'clock, rotating clockwise (90 is at 6 o'clock)
@property (nonatomic, assign) CGFloat joystickTilt;   // [0 - 1]

@property (nonatomic, assign) NSMutableArray* joystickPath; // The joystick's path since the last frame.

@property (nonatomic, assign) NSInteger numberOfTimesATapped; // Number of times A was tapped since the last frame.
@property (nonatomic, assign) NSInteger numberOfTimesBTapped; // Number of times B was tapped since the last frame.

@end

@interface PHMote()

@property (nonatomic, readonly) NSStream* stream;

- (void)addControllerState:(PHMoteState *)state;

@end

@interface PHMoteState : NSObject

- (id)initWithJoystickDegrees:(CGFloat)joystickDegrees joystickTilt:(CGFloat)joystickTilt;
- (id)initWithATapped;
- (id)initWithBTapped;

@property (nonatomic, readonly) CGFloat joystickDegrees;// [0 - 360), 0 being at 3 o'clock, rotating clockwise (90 is at 6 o'clock)
@property (nonatomic, readonly) CGFloat joystickTilt;   // [0 - 1]

@property (nonatomic, readonly) BOOL aIsTapped;
@property (nonatomic, readonly) BOOL bIsTapped;

@property (nonatomic, readonly) NSTimeInterval timestamp;

@end
