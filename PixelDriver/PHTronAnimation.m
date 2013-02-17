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

#import "PHTronAnimation.h"

typedef enum {
  PHTronStateWaitingForPlayers,
  PHTronStateCountdown,
  PHTronStatePlaying,
  PHTronStateEndGame,
} PHTronState;

static const NSTimeInterval kTimeToNextMoveTick = 0.3;

static const CGFloat kFontSize = 20;
static const CGFloat kSmallFontSize = 12;

CGPoint startingPositions[5] = {
  {10, 10},
  {38, 22},
  {38, 10},
  {10, 22},
  {24, 16},
};

NSColor* colors[5];

@interface PHTronPlayer : NSObject

@property (nonatomic, copy) NSString* name;
@property (nonatomic, assign) CGPoint pos;
@property (nonatomic, assign) CGPoint initialPos;
@property (nonatomic, assign) CGPoint direction;
@property (nonatomic, strong) NSColor* color;
@property (nonatomic, assign) BOOL dead;

@end

@implementation PHTronPlayer
@end

@implementation PHTronAnimation {
  NSFont* _font;
  NSFont* _smallFont;
  NSMutableDictionary* _players;
  PHTronState _state;
  NSTimeInterval _countdownStartTime;

  NSTimeInterval _timeToNextMoveTick;

  CGContextRef _gameContextRef;
}

+ (void)initialize {
  colors[0] = [NSColor redColor];
  colors[1] = [NSColor blueColor];
  colors[2] = [NSColor greenColor];
  colors[3] = [NSColor orangeColor];
  colors[4] = [NSColor whiteColor];
}

- (void)dealloc {
  if (nil != _gameContextRef) {
    CGContextRelease(_gameContextRef);
  }
}

- (id)init {
  if ((self = [super init])) {
    _players = [NSMutableDictionary dictionary];
    _font = [NSFont fontWithName:@"Visitor TT1 BRK" size:kFontSize];
    _smallFont = [NSFont fontWithName:@"Visitor TT1 BRK" size:kSmallFontSize];

    _gameContextRef = PHCreate8BitBitmapContextWithSize(CGSizeMake(kWallWidth, kWallHeight));
  }
  return self;
}

- (void)waitingForPlayers {
  for (PHMote* mote in self.driver.motes) {
    PHTronPlayer* player = _players[mote.identifier];
    if (nil == player) {
      player = [[PHTronPlayer alloc] init];
      for (NSInteger ix = 0; ix < 5; ++ix) {
        CGPoint position = startingPositions[ix];
        BOOL hasPosition = NO;
        for (PHTronPlayer* player in _players.allValues) {
          if (CGPointEqualToPoint(player.pos, position)) {
            hasPosition = YES;
            break;
          }
        }

        if (!hasPosition) {
          player.pos = position;
          player.color = colors[ix];
          break;
        }
      }

      int dir = arc4random_uniform(100);
      if (dir < 25) {
        player.direction = CGPointMake(1, 0);
      } else if (dir < 50) {
        player.direction = CGPointMake(0, 1);
      } else if (dir < 75) {
        player.direction = CGPointMake(-1, 0);
      } else {
        player.direction = CGPointMake(0, -1);
      }

      player.initialPos = player.pos;
      player.name = mote.name;
      _players[mote.identifier] = player;
    }
  }

  NSMutableArray* identifiersToRemove = [NSMutableArray array];
  for (NSString* identifier in _players) {
    BOOL foundMote = NO;
    for (PHMote* mote in self.driver.motes) {
      if ([mote.identifier isEqualToString:identifier]) {
        foundMote = YES;
        break;
      }
    }

    if (!foundMote) {
      [identifiersToRemove addObject:identifier];
    }
  }

  for (NSString* identifier in identifiersToRemove) {
    [_players removeObjectForKey:identifier];
  }
}

- (void)renderPlayersWithContext:(CGContextRef)cx size:(CGSize)size {
  CGRect pixel = CGRectMake(0, 0, 1, 1);
  for (PHTronPlayer* player in _players.allValues) {
    CGContextSetFillColorWithColor(cx, player.color.CGColor);
    pixel.origin = player.pos;
    CGContextFillRect(cx, pixel);
  }
}

- (void)renderCountdownWithContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);
  CGContextScaleCTM(cx, 1, -1);
  CGContextTranslateCTM(cx, 0, -size.height);

  CGContextSelectFont(cx,
                      [_font.fontName cStringUsingEncoding:NSUTF8StringEncoding],
                      _font.pointSize,
                      kCGEncodingMacRoman);
  CGContextTranslateCTM(cx, 1, 11);

  NSTimeInterval delta = [NSDate timeIntervalSinceReferenceDate] - _countdownStartTime;
  NSTimeInterval timeRemaining = 3 - delta;
  if (timeRemaining <= 0) {
    timeRemaining = 0;
    _state = PHTronStatePlaying;
    _timeToNextMoveTick = kTimeToNextMoveTick;
  }
  NSString* year = [NSString stringWithFormat:@"%d", (int)ceil(timeRemaining)];

  CGContextSetFillColorWithColor(cx, [NSColor whiteColor].CGColor);
  CGSize yearSize = NSSizeToCGSize([year sizeWithAttributes:@{NSFontAttributeName:_font}]);
  CGContextShowTextAtPoint(cx,
                           floorf((size.width - yearSize.width) / 2.),
                           0,
                           [year cStringUsingEncoding:NSUTF8StringEncoding],
                           year.length);
  CGContextRestoreGState(cx);
}

- (void)initializeGame {
  unsigned char* data = (unsigned char *)CGBitmapContextGetData(_gameContextRef);
  size_t bytesPerRow = CGBitmapContextGetBytesPerRow(_gameContextRef);

  for (NSString* identifier in _players) {
    PHTronPlayer* player = _players[identifier];
    CGPoint pos = player.pos;

    NSInteger offset = pos.x * 4 + (kWallHeight - 1 - pos.y) * bytesPerRow;
    CGFloat r,g,b,a;
    [player.color getRed:&r green:&g blue:&b alpha:&a];
    data[offset + 0] = r * 255;
    data[offset + 1] = g * 255;
    data[offset + 2] = b * 255;
    data[offset + 3] = 255;
  }
}

- (void)tickGame {
  unsigned char* data = (unsigned char *)CGBitmapContextGetData(_gameContextRef);
  size_t bytesPerRow = CGBitmapContextGetBytesPerRow(_gameContextRef);

  _timeToNextMoveTick -= self.secondsSinceLastTick * (1 + self.bassDegrader.value * 5);
  BOOL movePlayers = NO;
  if (_timeToNextMoveTick <= 0) {
    _timeToNextMoveTick = kTimeToNextMoveTick;
    movePlayers = YES;
  }

  NSInteger numberAlive = 0;
  for (NSString* identifier in _players) {
    PHTronPlayer* player = _players[identifier];
    CGPoint pos = player.pos;

    PHMote* playerMote = nil;
    for (PHMote* mote in self.driver.motes) {
      if ([mote.identifier isEqualToString:identifier]) {
        playerMote = mote;
        break;
      }
    }
    if (playerMote.joystickTilt > 0.9) {
      CGFloat degrees = playerMote.joystickDegrees;
      CGPoint newDirection = CGPointMake(0, 0);
      if (degrees < 45) {
        newDirection = CGPointMake(1, 0);
      } else if (degrees < 135) {
        newDirection = CGPointMake(0, 1);
      } else if (degrees < 225) {
        newDirection = CGPointMake(-1, 0);
      } else if (degrees < 315) {
        newDirection = CGPointMake(0, -1);
      } else if (degrees < 360) {
        newDirection = CGPointMake(1, 0);
      }
      if (newDirection.x != 0 || newDirection.y != 0) {
        if (newDirection.x == -player.direction.x
            || newDirection.y == -player.direction.y) {

        } else {
          player.direction = newDirection;
        }
      }
    }

    if (movePlayers && !player.dead) {
      CGPoint nextPos = CGPointMake(fmod((pos.x + player.direction.x + kWallWidth), kWallWidth),
                                    fmod((pos.y + player.direction.y + kWallHeight), kWallHeight));

      NSInteger nextOffset = nextPos.x * 4 + (kWallHeight - 1 - nextPos.y) * bytesPerRow;
      if (data[nextOffset + 3] != 0) {
        player.dead = YES;
      } else {
        CGFloat r,g,b,a;
        [player.color getRed:&r green:&g blue:&b alpha:&a];
        data[nextOffset + 0] = r * 255;
        data[nextOffset + 1] = g * 255;
        data[nextOffset + 2] = b * 255;
        data[nextOffset + 3] = 255;
        player.pos = nextPos;
      }
    }

    numberAlive += (player.dead ? 0 : 1);
  }

  if (numberAlive <= 1) {
    _state = PHTronStateEndGame;
  }
}

- (void)renderGameInContext:(CGContextRef)cx size:(CGSize)size {
  CGImageRef imageRef = CGBitmapContextCreateImage(_gameContextRef);
  CGContextDrawImage(cx, CGRectMake(0, 0, size.width, size.height), imageRef);
  CGImageRelease(imageRef);
}

- (void)renderWinnersWithContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);
  CGContextScaleCTM(cx, 1, -1);
  CGContextTranslateCTM(cx, 0, -size.height);

  CGContextSelectFont(cx,
                      [_smallFont.fontName cStringUsingEncoding:NSUTF8StringEncoding],
                      _smallFont.pointSize,
                      kCGEncodingMacRoman);
  CGContextTranslateCTM(cx, 1, 8);

  for (PHTronPlayer* player in _players.allValues) {
    if (player.dead) {
      continue;
    }
    CGContextSetFillColorWithColor(cx, [NSColor whiteColor].CGColor);
    CGSize yearSize = NSSizeToCGSize([player.name sizeWithAttributes:@{NSFontAttributeName:_smallFont}]);
    CGContextShowTextAtPoint(cx,
                             floorf((size.width - yearSize.width) / 2.),
                             0,
                             [player.name cStringUsingEncoding:NSUTF8StringEncoding],
                             player.name.length);
    CGContextTranslateCTM(cx, 0, yearSize.height);
  }
  CGContextRestoreGState(cx);
}

- (BOOL)anyButtonsPressed {
  for (PHMote* mote in self.driver.motes) {
    if (mote.numberOfTimesATapped || mote.numberOfTimesBTapped) {
      return YES;
    }
  }
  return NO;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);
  switch (_state) {
    case PHTronStateWaitingForPlayers:
      [self waitingForPlayers];
      [self renderPlayersWithContext:cx size:size];

      if ([self anyButtonsPressed]) {
        _state = PHTronStateCountdown;
        _countdownStartTime = [NSDate timeIntervalSinceReferenceDate];
        [self initializeGame];
      }
      break;

    case PHTronStateCountdown:
      [self renderGameInContext:cx size:size];
      [self renderCountdownWithContext:cx size:size];
      break;

    case PHTronStatePlaying:
      [self tickGame];
      [self renderGameInContext:cx size:size];
      break;

    case PHTronStateEndGame:
      [self renderGameInContext:cx size:size];
      [self renderWinnersWithContext:cx size:size];

      if ([self anyButtonsPressed]) {
        _state = PHTronStateWaitingForPlayers;

        unsigned char* data = (unsigned char *)CGBitmapContextGetData(_gameContextRef);
        size_t bytesPerRow = CGBitmapContextGetBytesPerRow(_gameContextRef);
        memset(data, 0, bytesPerRow * kWallHeight);

        for (PHTronPlayer* player in _players.allValues) {
          player.dead = NO;
          player.pos = player.initialPos;
        }
      }
      break;

    default:
      break;
  }
  CGContextRestoreGState(cx);
}

@end
