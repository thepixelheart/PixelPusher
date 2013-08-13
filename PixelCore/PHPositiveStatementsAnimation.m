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

#import "PHPositiveStatementsAnimation.h"

#import "PHFont.h"

static const NSTimeInterval kDisplayDuration = 10;
static const NSTimeInterval kFadeOutDuration = 1;
static const NSTimeInterval kFadeInDuration = 1;

typedef enum {
  PHPositiveStatementStateWaiting,
  PHPositiveStatementStateTransitionOut,
  PHPositiveStatementStateTransitionIn,
} PHPositiveStatementState;

static NSString* const kPositiveStatements[] = {
  @"Adventure",
  @"Art",
  @"Beauty",
  @"Bliss",
  @"Dancing",
  @"Ecstasy",
  @"Euphoria",
  @"Expression",
  @"Friends",
  @"Happiness",
  @"Health",
  @"Hugs",
  @"Joy",
  @"Laugh",
  @"Love",
  @"Luck",
  @"Music",
  @"Playa",
  @"Smiles",
};

@implementation PHPositiveStatementsAnimation {
  NSString* _currentStatement;
  NSTimeInterval _accum;
  PHPositiveStatementState _state;
}

- (id)init {
  if ((self = [super init])) {
    [self pickStatement];
  }
  return self;
}

- (void)pickStatement {
  NSString* statement = nil;
  do {
    statement = kPositiveStatements[arc4random_uniform(sizeof(kPositiveStatements) / sizeof(kPositiveStatements[0]))];
  } while ([statement isEqualToString:_currentStatement]);
  _currentStatement = statement;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  _accum += self.secondsSinceLastTick;

  CGContextSaveGState(cx);
  if (self.animationTick.hardwareState.didTapUserButton1
      || self.animationTick.hardwareState.didTapUserButton2) {
    [self pickStatement];
    _state = PHPositiveStatementStateWaiting;
    _accum = 0;
  } else {
    if (_state == PHPositiveStatementStateWaiting && _accum >= kDisplayDuration) {
      _state = PHPositiveStatementStateTransitionOut;
      _accum = 0;
    } else if (_state == PHPositiveStatementStateTransitionOut && _accum >= kFadeOutDuration) {
      _state = PHPositiveStatementStateTransitionIn;
      _accum = 0;
      [self pickStatement];
    } else if (_state == PHPositiveStatementStateTransitionIn && _accum >= kFadeInDuration) {
      _state = PHPositiveStatementStateWaiting;
      _accum = 0;
    }
    
    if (_state == PHPositiveStatementStateTransitionOut) {
      CGContextSetAlpha(cx, 1 - _accum / kFadeOutDuration);
    } else if (_state == PHPositiveStatementStateTransitionIn) {
      CGContextSetAlpha(cx, _accum / kFadeInDuration);
    }
  }
  
  CGSize stringSize = [PHFont sizeOfString:_currentStatement withConstraints:size];
  CGContextRef stringContextRef = PHCreate8BitBitmapContextWithSize(stringSize);
  [PHFont renderString:_currentStatement inRect:CGRectMake(0,
                                                           0,
                                                           stringSize.width,
                                                           stringSize.height) inContext:stringContextRef];
  CGImageRef imageRef = CGBitmapContextCreateImage(stringContextRef);
  CGContextDrawImage(cx, CGRectMake(floor((size.width - stringSize.width) / 2),
                                    floor((size.height - stringSize.height) / 2),
                                    stringSize.width,
                                    stringSize.height), imageRef);
  CGImageRelease(imageRef);
  CGContextRelease(stringContextRef);
  CGContextRestoreGState(cx);
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  [self renderBitmapInContext:cx size:size];
}

@end
