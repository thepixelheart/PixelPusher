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

#import "PHHardwareState.h"

@interface PHHardwareState ()

@property (nonatomic, assign) NSInteger numberOfRotationTicks; // negative or positive
@property (nonatomic, assign) CGFloat fader; // -0.5...0.5
@property (nonatomic, assign) CGFloat volume; // 0...1
@property (nonatomic, assign) BOOL playing;

@property (nonatomic, assign) BOOL didTapUserButton1;
@property (nonatomic, assign) BOOL didTapUserButton2;
@property (nonatomic, assign) BOOL isUserButton1Pressed;
@property (nonatomic, assign) BOOL isUserButton2Pressed;

- (void)recordBeat;

- (void)didPressLaunchpadButtonAtX:(NSInteger)x y:(NSInteger)y;

- (void)tick;

@end
