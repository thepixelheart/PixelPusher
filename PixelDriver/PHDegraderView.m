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

#import "PHDegraderView.h"

#import "PHAnimationDriver.h"

@interface PHDegraderHistoryItem : NSObject {
@public
  CGFloat _amplitudes[4];
}
@end

@implementation PHDegraderHistoryItem
@end

@implementation PHDegraderView {
  NSMutableArray* _history;
  NSColor* _colors[4];
}

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    _history = [NSMutableArray array];
    _colors[0] = [NSColor redColor];
    _colors[1] = [NSColor greenColor];
    _colors[2] = [NSColor blueColor];
    _colors[3] = [NSColor orangeColor];
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size driver:(PHAnimationDriver *)driver systemTick:(PHSystemTick *)systemTick {
  PHDegraderHistoryItem* item = [[PHDegraderHistoryItem alloc] init];
  item->_amplitudes[0] = driver.subBassAmplitude;
  item->_amplitudes[1] = driver.hihatAmplitude;
  item->_amplitudes[2] = driver.snareAmplitude;
  item->_amplitudes[3] = driver.vocalAmplitude;
  [_history addObject:item];

  while (_history.count > size.width) {
    [_history removeObjectAtIndex:0];
  }

  CGContextSetInterpolationQuality(cx, kCGInterpolationNone);
  CGFloat quadrantHeight = size.height / 4;
  for (NSInteger ix = 0; ix < 4; ++ix) {
    CGContextBeginPath(cx);
    BOOL plotted = NO;
    CGFloat quadrantBottom = (CGFloat)ix * size.height / 4.0;

    CGFloat x = size.width - _history.count;
    for (PHDegraderHistoryItem* item in _history) {
      CGFloat y = item->_amplitudes[ix] * quadrantHeight;
      if (!plotted) {
        plotted = YES;
        CGContextMoveToPoint(cx, x, y + quadrantBottom);
      } else {
        CGContextAddLineToPoint(cx, x, y + quadrantBottom);
      }
      ++x;
    }

    CGContextSetStrokeColorWithColor(cx, _colors[ix].CGColor);

    CGContextStrokePath(cx);
  }
}

- (double)threadPriority {
  return 0.2;
}

@end
