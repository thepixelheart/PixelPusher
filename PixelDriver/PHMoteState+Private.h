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

#import "PHMote.h"

// Private APIs
@interface PHMoteState()

@property (nonatomic, assign) CGFloat joystickDegrees;
@property (nonatomic, assign) CGFloat joystickTilt;
@property (nonatomic, assign) BOOL aIsTapped;
@property (nonatomic, assign) BOOL bIsTapped;
@property (nonatomic, copy) NSString *text;

@property (nonatomic, assign) PHMoteStateControlEvent controlEvent;

@end
