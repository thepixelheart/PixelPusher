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
 * The composite state of a single PixelMote tracked since the last frame was displayed.
 *
 * A list of all currently connected motes is accessible via self.driver.motes.
 */
@interface PHMote : NSObject <NSCopying>

// The name provided by the owner of this mote.
@property (nonatomic, readonly, copy) NSString* name;

#pragma mark Composite Information

@property (nonatomic, assign) CGFloat joystickDegrees;// [0 - 360), 0 being at 3 o'clock, rotating clockwise (90 is at 6 o'clock)
@property (nonatomic, assign) CGFloat joystickTilt;   // [0 - 1]

@property (nonatomic, assign) NSInteger numberOfTimesATapped; // Number of times A was tapped since the last frame.
@property (nonatomic, assign) NSInteger numberOfTimesBTapped; // Number of times B was tapped since the last frame.

#pragma mark Raw Information

// All of the states that were sent since the last animation tick.
@property (nonatomic, readonly, copy) NSArray* statesSinceLastFrame; // Array of PHMoteState

@end

/**
 * A single state message sent by the PixelMote.
 */
@interface PHMoteState : NSObject

@property (nonatomic, readonly) CGFloat joystickDegrees;// [0 - 360), 0 being at 3 o'clock, rotating clockwise (90 is at 6 o'clock)
@property (nonatomic, readonly) CGFloat joystickTilt;   // [0 - 1]

@property (nonatomic, readonly) BOOL aIsTapped;
@property (nonatomic, readonly) BOOL bIsTapped;

@property (nonatomic, readonly) NSTimeInterval timestamp;

@end
