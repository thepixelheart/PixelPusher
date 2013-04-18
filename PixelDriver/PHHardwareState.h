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

@interface PHHardwareState : NSObject <NSCopying>
@property (nonatomic, readonly, assign) NSInteger numberOfRotationTicks; // negative or positive
@property (nonatomic, readonly, assign) CGFloat fader; // -0.5...0.5
@property (nonatomic, readonly, assign) CGFloat volume; // 0...1
@property (nonatomic, readonly, assign) BOOL playing;

@property (nonatomic, readonly, assign) BOOL didTapUserButton1;
@property (nonatomic, readonly, assign) BOOL didTapUserButton2;
@property (nonatomic, readonly, assign) BOOL isUserButton1Pressed;
@property (nonatomic, readonly, assign) BOOL isUserButton2Pressed;

@property (nonatomic, readonly, assign) NSTimeInterval lastBeatTime;
@property (nonatomic, readonly, assign) NSTimeInterval nextBeatTime;
@property (nonatomic, readonly, assign) CGFloat bpm;
@property (nonatomic, readonly, assign) BOOL isBeating;

- (BOOL)wasLaunchpadButtonPressedAtX:(NSInteger)x y:(NSInteger)y;

@end
