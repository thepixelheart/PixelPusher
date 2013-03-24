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

@interface PHTetrisPlayer : NSObject
@end

@implementation PHTetrisPlayer {
  CGContextRef _boardContextRef;
}

- (void)dealloc {
  if (nil != _boardContextRef) {
    CGContextRelease(_boardContextRef);
  }
}

- (id)init {
  if ((self = [super init])) {
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

- (void)renderGameInContext:(CGContextRef)cx panelIndex:(NSInteger)panelIndex {
  CGImageRef imageRef = CGBitmapContextCreateImage(_boardContextRef);
  CGFloat offset = [self offsetFromPanelIndex:panelIndex];
  CGContextDrawImage(cx, CGRectMake(0, 0, offset + 1, [self boardHeight]), imageRef);
  CGImageRelease(imageRef);

  CGContextSetFillColorWithColor(cx, [NSColor whiteColor].CGColor);
  CGContextFillRect(cx, CGRectMake(offset, 0, 1, [self boardHeight]));
  CGContextFillRect(cx, CGRectMake(offset + [self boardWidth] + 1, 0, 1, [self boardHeight]));
  CGContextFillRect(cx, CGRectMake(offset, [self boardHeight] - 1, [self boardWidth] + 2, 1));
}

- (void)tick {
  
}

@end

@implementation PHTetrisAnimation {
  NSMutableDictionary* _players;
}

- (id)init {
  if ((self = [super init])) {
    _players = [NSMutableDictionary dictionary];
  }
  return self;
}

- (PHTetrisPlayer *)createPlayerWithMote:(PHMote *)mote {
  PHTetrisPlayer *player = [[PHTetrisPlayer alloc] init];
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
      [player tick];
      [player renderGameInContext:cx panelIndex:panelIndex];
    }
    ++panelIndex;
  }
  CGContextRestoreGState(cx);
}

@end
