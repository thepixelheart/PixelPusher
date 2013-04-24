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

@implementation PHMoteState {
  BOOL _isxy;
}

- (id)init {
  if ((self = [super init])) {
    _timestamp = [NSDate timeIntervalSinceReferenceDate];
  }
  return self;
}

- (BOOL)isXy {
  return _isxy;
}

- (id)copyWithZone:(NSZone *)zone {
  PHMoteState* copy = [[[self class] allocWithZone:zone] init];
  copy->_joystickDegrees = _joystickDegrees;
  copy->_joystickTilt = _joystickTilt;
  copy->_aIsTapped = _aIsTapped;
  copy->_bIsTapped = _bIsTapped;
  copy->_text = _text;
  copy->_controlEvent = _controlEvent;
  copy->_isxy = _isxy;
  copy->_xy = _xy;
  return copy;
}

- (void)setXy:(CGPoint)xy {
  _xy = xy;
  _isxy = YES;
}

@end

@implementation PHMote {
  NSMutableArray* _states;
  NSMutableArray* _xyValues;
}

- (id)initWithName:(NSString *)name identifier:(NSString *)identifier stream:(NSStream *)stream {
  if ((self = [super init])) {
    _states = [NSMutableArray array];
    _xyValues = [NSMutableArray array];
    _name = [name copy];
    _identifier = [identifier copy];
    _stream = stream;
  }
  return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
  PHMote* copy = [[[self class] allocWithZone:zone] init];
  copy->_states = [_states mutableCopy];
  copy->_name = _name;
  copy->_identifier = _identifier;
  copy->_numberOfTimesATapped = _numberOfTimesATapped;
  copy->_numberOfTimesBTapped = _numberOfTimesBTapped;
  copy->_aIsBeingTapped = _aIsBeingTapped;
  copy->_bIsBeingTapped = _bIsBeingTapped;
  copy->_joystickDegrees = _joystickDegrees;
  copy->_joystickTilt = _joystickTilt;
  copy->_text = _text;
  copy->_xyValues = [_xyValues mutableCopy];
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
  _lastState = state;

  if (_aIsBeingTapped && !state.aIsTapped) {
    ++_numberOfTimesATapped;
  }
  if (_bIsBeingTapped && !state.bIsTapped) {
    ++_numberOfTimesBTapped;
  }
  _aIsBeingTapped = state.aIsTapped;
  _bIsBeingTapped = state.bIsTapped;
  _joystickDegrees = state.joystickDegrees;
  _joystickTilt = state.joystickTilt;
  if (state.text.length) {
    _text = state.text;
  }

  if (state.controlEvent == PHMoteStateControlEventStartStreaming) {
    _streaming = YES;
  } else if (state.controlEvent == PHMoteStateControlEventStopStreaming) {
    _streaming = NO;
  }

  if ([state isXy]) {
    [_xyValues addObject:[NSValue valueWithPoint:state.xy]];
  }
}

- (NSArray *)statesSinceLastFrame {
  return [_states copy];
}

- (NSArray *)xySinceLastFrame {
  return [_xyValues copy];
}

- (void)tick {
  _numberOfTimesATapped = 0;
  _numberOfTimesBTapped = 0;
  _text = nil;
  [_states removeAllObjects];
  [_xyValues removeAllObjects];
}

- (void)clearText {
}

@end
