//
// Copyright 2012 Jason Prado
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

#import "PHOverlay.h"

@implementation PHOverlay

+ (id)overlay {
  return [[self alloc] init];
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  // No-op
}

- (NSTimeInterval)secondsSinceLastTick {
  return (_lastTick > 0) ? ([NSDate timeIntervalSinceReferenceDate] - _lastTick) : 0;
}

- (void)bitmapWillStartRendering {
  // No-op
}

- (void)bitmapDidFinishRendering {
  _lastTick = [NSDate timeIntervalSinceReferenceDate];
}

@end
