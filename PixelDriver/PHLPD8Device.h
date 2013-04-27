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
#import "PHMIDIHardware.h"

@protocol PHLPD8DeviceDelegate;

@interface PHLPD8Device : PHMIDIHardware
@property (nonatomic, weak) id<PHLPD8DeviceDelegate> delegate;
@end

@protocol PHLPD8DeviceDelegate <NSObject>

- (void)volume:(NSInteger)volume didChangeValue:(CGFloat)value;
- (void)buttonWasPressed:(NSInteger)button withVelocity:(CGFloat)velocity;
- (void)buttonWasReleased:(NSInteger)button;

@end
