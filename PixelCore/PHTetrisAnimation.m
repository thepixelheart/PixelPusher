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

#import "PHTetrisAnimation.h"

static const CGFloat kFontSize = 20;

typedef enum {
  PHTetrisPlayerStateWaiting,
  PHTetrisPlayerStateCountingDown,
  PHTetrisPlayerStatePlaying,
} PHTetrisPlayerState;

@interface PHTetrisPlayer : NSObject
@end

@implementation PHTetrisPlayer {
  NSFont *_font;
  PHMote *_mote;
  CGContextRef _boardContextRef;
  PHTetrisPlayerState _state;
  NSTimeInterval _secondsSinceLastStateChange;
}

- (void)dealloc {
  if (nil != _boardContextRef) {
    CGContextRelease(_boardContextRef);
  }
}

- (id)initWithFont:(NSFont *)font mote:(PHMote *)mote {
  if ((self = [super init])) {
    _font = font;
    _mote = mote;
    _boardContextRef = PHCreate8BitBitmapContextWithSize(CGSizeMake([self boardWidth], [self boardHeight]));
  }
  return self;
}

- (CGFloat)boardWidth {
  return kWallWidth / 3 - 2;
}

- (CGFloat)boardHeight {
  return kWallHeight;
}

- (CGFloat)offsetFromPanelIndex:(NSInteger)panelIndex {
  if (panelIndex == 0) {
    return kWallWidth / 3;
  } else if (panelIndex == 1) {
    return kWallWidth * 2 / 3;
  } else {
    return 0;
  }
}

- (void)renderBoardInContext:(CGContextRef)cx {
  CGImageRef imageRef = CGBitmapContextCreateImage(_boardContextRef);
  CGContextDrawImage(cx, CGRectMake(0, 0, 1, [self boardHeight]), imageRef);
  CGImageRelease(imageRef);
}

- (void)renderBorderInContext:(CGContextRef)cx {
  CGContextFillRect(cx, CGRectMake(0, 0, 1, [self boardHeight] - 1));
  CGContextFillRect(cx, CGRectMake([self boardWidth] + 1, 0, 1, [self boardHeight] - 1));
  CGContextFillRect(cx, CGRectMake(0, [self boardHeight] - 1, [self boardWidth] + 2, 1));
}

- (void)renderCountdownInContext:(CGContextRef)cx {
  CGContextSaveGState(cx);
  CGContextScaleCTM(cx, 1, -1);
  CGContextTranslateCTM(cx, 0, -kWallHeight);

  CGContextSelectFont(cx,
                      [_font.fontName cStringUsingEncoding:NSUTF8StringEncoding],
                      _font.pointSize,
                      kCGEncodingMacRoman);
  CGContextTranslateCTM(cx, 1, 11);

  NSTimeInterval timeRemaining = 3 - _secondsSinceLastStateChange;

  NSString* year = [NSString stringWithFormat:@"%d", (int)ceil(timeRemaining)];

  CGContextSetFillColorWithColor(cx, [NSColor whiteColor].CGColor);
  CGSize yearSize = NSSizeToCGSize([year sizeWithAttributes:@{NSFontAttributeName:_font}]);
  CGContextShowTextAtPoint(cx,
                           floorf((kWallWidth / 3 - yearSize.width) / 2.),
                           0,
                           [year cStringUsingEncoding:NSUTF8StringEncoding],
                           year.length);
  CGContextRestoreGState(cx);
}

- (void)renderCurrentStateInContext:(CGContextRef)cx {
  switch (_state) {
    case PHTetrisPlayerStateWaiting: {
      CGFloat amp = sinf(_secondsSinceLastStateChange * 3) * 0.3 + 0.3 + 0.4;
      NSColor *color = [NSColor colorWithDeviceWhite:amp alpha:1];
      CGContextSetFillColorWithColor(cx, color.CGColor);
      [self renderBorderInContext:cx];
      break;
    }

    case PHTetrisPlayerStateCountingDown: {
      CGContextSetFillColorWithColor(cx, [NSColor whiteColor].CGColor);
      [self renderBorderInContext:cx];
      [self renderCountdownInContext:cx];
      break;
    }

    default:
      break;
  }
}

- (void)renderGameInContext:(CGContextRef)cx panelIndex:(NSInteger)panelIndex {
  CGContextSaveGState(cx);
  CGFloat offset = [self offsetFromPanelIndex:panelIndex];
  CGContextTranslateCTM(cx, offset, 0);
  [self renderCurrentStateInContext:cx];
  CGContextRestoreGState(cx);
}

- (void)tickWithDelta:(NSTimeInterval)delta {
  _secondsSinceLastStateChange += delta;

  switch (_state) {
    case PHTetrisPlayerStateWaiting:
      if (_mote.numberOfTimesATapped
          || _mote.numberOfTimesBTapped) {
        _secondsSinceLastStateChange = 0;
        _state = PHTetrisPlayerStateCountingDown;
      }
      _secondsSinceLastStateChange = 0;
      _state = PHTetrisPlayerStateCountingDown;
      break;
    case PHTetrisPlayerStateCountingDown: {
      NSTimeInterval timeRemaining = 3 - _secondsSinceLastStateChange;

      if (timeRemaining <= 0) {
        _secondsSinceLastStateChange = 0;
        _state = PHTetrisPlayerStatePlaying;
      }
      break;
    }

    default:
      break;
  }
}

@end

@implementation PHTetrisAnimation {
  NSFont *_font;
  NSMutableDictionary* _players;
}

- (id)init {
  if ((self = [super init])) {
    _font = [NSFont fontWithName:@"Visitor TT1 BRK" size:kFontSize];
    _players = [NSMutableDictionary dictionary];
  }
  return self;
}

- (PHTetrisPlayer *)createPlayerWithMote:(PHMote *)mote {
  PHTetrisPlayer *player = [[PHTetrisPlayer alloc] initWithFont:_font mote:mote];
  _players[mote.identifier] = player;
  return player;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);
  NSInteger panelIndex = 0;
  for (PHMote *mote in self.systemState.motes) {
    PHTetrisPlayer *player = _players[mote.identifier];
    if (nil == player) {
      player = [self createPlayerWithMote:mote];
    }
    if (panelIndex < 3) {
      [player tickWithDelta:self.secondsSinceLastTick];
      [player renderGameInContext:cx panelIndex:panelIndex];
    }
    ++panelIndex;
  }
  CGContextRestoreGState(cx);
}

@end
