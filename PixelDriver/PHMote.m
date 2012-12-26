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

#import "PHMote+Private.h"
#import "PHMoteState+Private.h"

@implementation PHMoteState

- (id)init {
  if ((self = [super init])) {
    _timestamp = [NSDate timeIntervalSinceReferenceDate];
  }
  return self;
}

- (id)initWithJoystickDegrees:(CGFloat)joystickDegrees joystickTilt:(CGFloat)joystickTilt {
  if ((self = [self init])) {
    _joystickDegrees = joystickDegrees;
    _joystickTilt = joystickTilt;
  }
  return self;
}

- (id)initWithATapped {
  if ((self = [self init])) {
    _aIsTapped = YES;
  }
  return self;
}

- (id)initWithBTapped {
  if ((self = [self init])) {
    _bIsTapped = YES;
  }
  return self;
}

@end

@implementation PHMote {
  NSMutableArray* _states;
}

- (id)initWithName:(NSString *)name stream:(NSStream *)stream {
  if ((self = [super init])) {
    _name = [name copy];
    _stream = stream;
  }
  return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
  PHMote* copy = [[[self class] allocWithZone:zone] init];
  copy->_states = [_states copy];
  copy->_numberOfTimesATapped = _numberOfTimesATapped;
  copy->_numberOfTimesBTapped = _numberOfTimesBTapped;
  copy->_joystickDegrees = _joystickDegrees;
  copy->_joystickTilt = _joystickTilt;
  return copy;
}

- (NSString *)description {
  return [NSString stringWithFormat:
          @"<%@ \"%@\" joystick angle: %.2f - joystick tilt: %.4f - # times A pressed: %ld - # times B pressed: %ld",
          [super description],
          _name,
          _joystickDegrees,
          _joystickTilt,
          _numberOfTimesATapped,
          _numberOfTimesBTapped];
}

- (void)addControllerState:(PHMoteState *)state {
  [_states addObject:state];

  _numberOfTimesATapped += state.aIsTapped ? 1 : 0;
  _numberOfTimesBTapped += state.bIsTapped ? 1 : 0;
  _joystickDegrees = state.joystickDegrees;
  _joystickTilt = state.joystickTilt;
}

- (void)tick {
  _numberOfTimesATapped = 0;
  _numberOfTimesBTapped = 0;
  [_states removeAllObjects];
}

@end
