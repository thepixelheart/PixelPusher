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

@implementation PHHardwareState

- (id)init {
  if ((self = [super init])) {
    _volume = 0.5;
    _playing = YES;
  }
  return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
  PHHardwareState *state = [[[self class] allocWithZone:zone] init];
  state->_numberOfRotationTicks = _numberOfRotationTicks;
  state->_fader = _fader;
  state->_volume = _volume;
  state->_playing = _playing;
  state->_isUserButton1Pressed = _isUserButton1Pressed;
  state->_isUserButton2Pressed = _isUserButton2Pressed;
  state->_didTapUserButton1 = _didTapUserButton1;
  state->_didTapUserButton2 = _didTapUserButton2;
  return state;
}

#pragma mark - Public Methods

- (void)setIsUserButton1Pressed:(BOOL)isUserButton1Pressed {
  _isUserButton1Pressed = isUserButton1Pressed;

  _didTapUserButton1 = _didTapUserButton1 || _isUserButton1Pressed;
}

- (void)setIsUserButton2Pressed:(BOOL)isUserButton2Pressed {
  _isUserButton2Pressed = isUserButton2Pressed;

  _didTapUserButton2 = _didTapUserButton2 || _isUserButton2Pressed;
}

- (void)tick {
  _numberOfRotationTicks = 0;
  _didTapUserButton1 = NO;
  _didTapUserButton2 = NO;
}

@end
