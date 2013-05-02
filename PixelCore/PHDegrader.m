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

#import "PHDegrader.h"

@implementation PHDegrader {
  NSTimeInterval _lastTick;
  CGFloat _value;
}

- (id)init {
  if ((self = [super init])) {
    _deltaPerSecond = 1;
  }
  return self;
}

- (void)tickWithPeak:(CGFloat)peak {
  if (_lastTick > 0) {
    NSTimeInterval delta = [NSDate timeIntervalSinceReferenceDate] - _lastTick;
    _value -= delta * _deltaPerSecond;
  }

  _value = MAX(_value, peak);

  _lastTick = [NSDate timeIntervalSinceReferenceDate];
}

- (void)tickWithPeak:(CGFloat)peak delta:(CGFloat)delta {
  if (_lastTick > 0) {
    _value -= delta * _deltaPerSecond;
  }

  _value = MAX(_value, peak);

  _lastTick = [NSDate timeIntervalSinceReferenceDate];
}

@end
