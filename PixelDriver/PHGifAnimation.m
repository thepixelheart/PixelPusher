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

#import "PHGifAnimation.h"

static const NSInteger kWaitToChangeDurationMin = 400;
static const NSInteger kWaitToChangeDurationMax = 800;
static const NSTimeInterval kTransitionDuration = 0.5;

@implementation PHGifAnimation {
  NSImage* _activeGif;
  NSImage* _previousGif;
  BOOL _hasPlayedOnce;
  NSTimeInterval _nextFrameTick;
  NSTimeInterval _nextFrameTickForPreviousGif;

  NSTimeInterval _transitionStartedAtTick;

  NSTimeInterval _nextGifChangeTick;
  BOOL _buttonWasntPressed;
}

- (id)init {
  if ((self = [super init])) {
    _buttonWasntPressed = YES;
  }
  return self;
}

- (void)drawGif:(NSImage *)gif inContext:(CGContextRef)cx size:(CGSize)size nextFrameTick:(NSTimeInterval *)nextFrameTick alpha:(CGFloat)alpha {
  if (nil == gif) {
    return;
  }

  CGContextSaveGState(cx);
  NSBitmapImageRep* bitmapImage = [[gif representations] objectAtIndex:0];

  int currentFrame = [[bitmapImage valueForProperty:NSImageCurrentFrame] intValue];
  if (0 == *nextFrameTick) {
    float duration = [[bitmapImage valueForProperty:NSImageCurrentFrameDuration] floatValue];
    *nextFrameTick = [NSDate timeIntervalSinceReferenceDate] + duration;

  } else if ([NSDate timeIntervalSinceReferenceDate] >= *nextFrameTick) {
    NSInteger numberOfFrames = [[bitmapImage valueForProperty:NSImageFrameCount] intValue];
    if (0 == numberOfFrames) {
      numberOfFrames = 1;
    }
    currentFrame = (currentFrame + 1) % numberOfFrames;
    if (currentFrame == 0 && gif == _activeGif && !_hasPlayedOnce) {
      _hasPlayedOnce = YES;

      _nextGifChangeTick = [NSDate timeIntervalSinceReferenceDate] + (NSTimeInterval)(arc4random_uniform(kWaitToChangeDurationMax - kWaitToChangeDurationMin) + kWaitToChangeDurationMin) / 100. + kTransitionDuration;
    }
    [bitmapImage setProperty:NSImageCurrentFrame withValue:[NSNumber numberWithInt:currentFrame]];

    float duration = [[bitmapImage valueForProperty:NSImageCurrentFrameDuration] floatValue];
    *nextFrameTick = [NSDate timeIntervalSinceReferenceDate] + duration;
  }

  CGSize imageSize = bitmapImage.size;

  CGContextScaleCTM(cx, 1, -1);
  CGContextTranslateCTM(cx, 0, -size.height);

  NSGraphicsContext* gcx = [NSGraphicsContext graphicsContextWithGraphicsPort:cx flipped:NO];
  [NSGraphicsContext saveGraphicsState];
  [NSGraphicsContext setCurrentContext:gcx];

  CGRect imageFrame = CGRectMake(0, 0, imageSize.width, imageSize.height);
  CGRect frame = CGRectMake(floorf((size.width - imageSize.width) / 2),
                            floorf((size.height - imageSize.height) / 2),
                            imageSize.width, imageSize.height);

  [bitmapImage drawInRect:frame fromRect:imageFrame operation:NSCompositeSourceOver fraction:alpha respectFlipped:YES hints:nil];

  [NSGraphicsContext restoreGraphicsState];
  CGContextRestoreGState(cx);
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  @synchronized(self) {
    CGContextSaveGState(cx);

    BOOL buttonPressed = self.driver.isUserButton1Pressed || self.driver.isUserButton2Pressed;
    if (!buttonPressed) {
      _buttonWasntPressed = YES;
    }

    if ((nil == _activeGif && self.driver.gifs.count > 0)
        || (((_hasPlayedOnce
              && [NSDate timeIntervalSinceReferenceDate] >= _nextGifChangeTick)
             || (buttonPressed && _buttonWasntPressed))
            && self.driver.gifs.count > 1)) {
      _buttonWasntPressed = NO;
      NSMutableArray* notThisGifGifs = [self.driver.gifs mutableCopy];
      if (nil != _activeGif) {
        [notThisGifGifs removeObject:_activeGif];
      }
      _nextFrameTickForPreviousGif = _nextFrameTick;
      if (!self.driver.isUserButton2Pressed) {
        _previousGif = _activeGif;
      }
      _activeGif = notThisGifGifs[arc4random_uniform(notThisGifGifs.count)];
      _transitionStartedAtTick = [NSDate timeIntervalSinceReferenceDate];
      _hasPlayedOnce = NO;
    }

    CGFloat alpha = 1;
    if (nil != _previousGif) {
      CGFloat t = MIN(1, ([NSDate timeIntervalSinceReferenceDate] - _transitionStartedAtTick) / kTransitionDuration);
      alpha = PHEaseInEaseOut(t);
    }

    CGContextSetAlpha(cx, alpha);

    [self drawGif:_activeGif inContext:cx size:size nextFrameTick:&_nextFrameTick alpha:alpha];

    if (nil != _previousGif) {
      CGContextSetAlpha(cx, 1 - alpha);
      [self drawGif:_previousGif inContext:cx size:size nextFrameTick:&_nextFrameTickForPreviousGif alpha:1 - alpha];

      if ([NSDate timeIntervalSinceReferenceDate] - _transitionStartedAtTick >= kTransitionDuration) {
        _previousGif = nil;
      }
    }

    CGContextRestoreGState(cx);
  }
}

- (NSString *)tooltipName {
  return @"gifs";
}

@end
