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
#import "PHHardwareState+System.h"

#import "PHLaunchpadDevice.h"

static const NSInteger kMaxNumberOfBeats = 10;

@implementation PHHardwareState {
  BOOL _launchpadButtonState[64];
  NSMutableArray* _recordedBeatTimes;
  NSTimeInterval _queuedTime1;
}

@synthesize numberOfRotationTicks = _numberOfRotationTicks;
@synthesize fader = _fader;
@synthesize volume = _volume;
@synthesize playing = _playing;
@synthesize didTapUserButton1 = _didTapUserButton1;
@synthesize didTapUserButton2 = _didTapUserButton2;
@synthesize isUserButton1Pressed = _isUserButton1Pressed;
@synthesize isUserButton2Pressed = _isUserButton2Pressed;

- (id)init {
  if ((self = [super init])) {
    _recordedBeatTimes = [NSMutableArray array];
    _volume = 0.5;
    _playing = YES;
    memset(_launchpadButtonState, 0, sizeof(BOOL) * 64);
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
  state->_recordedBeatTimes = [_recordedBeatTimes mutableCopy];
  state->_queuedTime1 = _queuedTime1;
  memcpy(state->_launchpadButtonState, _launchpadButtonState, sizeof(BOOL) * 64);
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

- (void)recordBeat {
  NSTimeInterval currentTick = [NSDate timeIntervalSinceReferenceDate];

  BOOL shouldRecordBeat = YES;
  if ([self canPredictBeat]) {
    // Try to avoid killing existing bpm if there was a significant gap between
    // the last time we tried to record beats.
    NSTimeInterval lastRecordedBeat = [self lastRecordedBeat];
    if (currentTick - lastRecordedBeat > 1) {
      if (_queuedTime1 == 0 || (currentTick - _queuedTime1) > 1) {
        _queuedTime1 = currentTick;
        shouldRecordBeat = NO;

      } else {
        [_recordedBeatTimes removeAllObjects];
        // queued time 1 is valid and delta between that and this one is reasonable.
        [_recordedBeatTimes addObject:@(_queuedTime1)];
        _queuedTime1 = 0;
      }
    }
  }
  if (shouldRecordBeat) {
    [_recordedBeatTimes addObject:@(currentTick)];
  }

  while ([_recordedBeatTimes count] > kMaxNumberOfBeats) {
    [_recordedBeatTimes removeObjectAtIndex:0];
  }
}

- (void)clearBpm {
  _queuedTime1 = 0;
  [_recordedBeatTimes removeAllObjects];
}

- (NSTimeInterval)averageTimeBetweenBeats {
  if (_recordedBeatTimes.count <= 1) {
    return -1;
  }

  NSTimeInterval totalDelta = 0;
  NSNumber* lastTick = nil;
  for (NSNumber* tick in _recordedBeatTimes) {
    if (nil != lastTick) {
      totalDelta += [tick doubleValue] - [lastTick doubleValue];
    }
    lastTick = tick;
  }

  return totalDelta / (NSTimeInterval)(_recordedBeatTimes.count - 1);
}

- (NSTimeInterval)lastRecordedBeat {
  return [[_recordedBeatTimes lastObject] doubleValue];
}

- (BOOL)canPredictBeat {
  return _recordedBeatTimes.count >= 2;
}

- (NSTimeInterval)lastBeatTime {
  if (![self canPredictBeat]) {
    return -1;
  }

  NSTimeInterval lastRecordedBeat = [self lastRecordedBeat];
  NSTimeInterval currentTick = [NSDate timeIntervalSinceReferenceDate];
  NSTimeInterval delta = currentTick - lastRecordedBeat;
  NSTimeInterval averageTimeBetweenBeats = [self averageTimeBetweenBeats];
  NSTimeInterval nummberOfSlices = floor(delta / averageTimeBetweenBeats);
  return lastRecordedBeat + nummberOfSlices * averageTimeBetweenBeats;
}

- (NSTimeInterval)nextBeatTime {
  if (![self canPredictBeat]) {
    return -1;
  }
  return [self lastBeatTime] + [self averageTimeBetweenBeats];
}

- (CGFloat)bpm {
  if (![self canPredictBeat]) {
    return -1;
  }

  NSTimeInterval averageTimeBetweenBeats = [self averageTimeBetweenBeats];
  if (averageTimeBetweenBeats > 0) {
    return 60 / averageTimeBetweenBeats;
  } else {
    return -1;
  }
}

- (BOOL)isBeating {
  if (![self canPredictBeat]) {
    return 0;
  }

  NSTimeInterval lastBeatTime = [self lastBeatTime];
  NSTimeInterval nextBeatTime = [self nextBeatTime];
  NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
  return ((currentTime - lastBeatTime < 0.1)
          || (nextBeatTime - currentTime < 0.1));
}

- (void)tick {
  _numberOfRotationTicks = 0;
  _didTapUserButton1 = NO;
  _didTapUserButton2 = NO;

  memset(_launchpadButtonState, 0, sizeof(BOOL) * 64);
}

- (void)didPressLaunchpadButtonAtX:(NSInteger)x y:(NSInteger)y {
  _launchpadButtonState[x + y * PHLaunchpadButtonGridWidth] = YES;
}

- (BOOL)wasLaunchpadButtonPressedAtX:(NSInteger)x y:(NSInteger)y {
  return _launchpadButtonState[x + y * PHLaunchpadButtonGridWidth];
}

@end
