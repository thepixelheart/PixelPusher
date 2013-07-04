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

#import "AppDelegate.h"

static const NSInteger kWaitToChangeDurationMin = 400;
static const NSInteger kWaitToChangeDurationMax = 800;
static const NSTimeInterval kTransitionDuration = 0.5;

@implementation PHGifAnimation {
  NSImage* _activeGif;
  NSImage* _previousGif;
  BOOL _hasPlayedOnce;
  NSTimeInterval _nextFrameTick;
  NSTimeInterval _nextFrameTickForPreviousGif;
  int _currentGifIndex;

  NSTimeInterval _transitionStartedAtTick;

  NSTimeInterval _nextGifChangeTick;
  BOOL _buttonWasntPressed;
}

- (id)init {
  if ((self = [super init])) {
    _buttonWasntPressed = YES;
    _nextFrameTick = CGFLOAT_MAX;
    _nextFrameTickForPreviousGif = CGFLOAT_MAX;
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
  if (CGFLOAT_MAX == *nextFrameTick) {
    float duration = [[bitmapImage valueForProperty:NSImageCurrentFrameDuration] floatValue];
    *nextFrameTick = duration;
  }

  *nextFrameTick -= self.secondsSinceLastTick;
  if (*nextFrameTick <= 0) {
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
    *nextFrameTick = duration;
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

- (NSString *)filter {
  return nil;
}

- (NSArray *)filteredGifs {
  NSArray* allGifs = self.systemState.gifs;

  NSString* filter = [self filter];
  if (filter) {
    return [allGifs filteredArrayUsingPredicate:
            [NSPredicate predicateWithBlock:
             ^BOOL(id evaluatedObject, NSDictionary *bindings) {
               PHGif* gif = evaluatedObject;
               return [gif.filename rangeOfString:filter].length > 0;
             }]];
  } else {
    return allGifs;
  }
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  @synchronized(self) {
    CGContextSaveGState(cx);

    BOOL buttonPressed = self.animationTick.hardwareState.isUserButton1Pressed || self.animationTick.hardwareState.isUserButton2Pressed;
    if (!buttonPressed) {
      _buttonWasntPressed = YES;
    }

    if ((nil == _activeGif && self.systemState.gifs.count > 0)
        || (((_hasPlayedOnce
              && [NSDate timeIntervalSinceReferenceDate] >= _nextGifChangeTick)
             || (buttonPressed && _buttonWasntPressed))
            && self.systemState.gifs.count > 1)) {
      if (nil == _activeGif) {
        _currentGifIndex = arc4random_uniform((u_int32_t)self.systemState.gifs.count);
      }
      _buttonWasntPressed = NO;

      if (self.animationTick.hardwareState.isUserButton1Pressed) {
        _currentGifIndex--;
      } else {
        _currentGifIndex++;
      }
      _nextFrameTickForPreviousGif = _nextFrameTick;
      if (!self.animationTick.hardwareState.isUserButton2Pressed
          && !self.animationTick.hardwareState.isUserButton1Pressed) {
        _previousGif = _activeGif;
      }
      NSArray* filteredGifs = [self filteredGifs];
      _activeGif = [filteredGifs[(_currentGifIndex % filteredGifs.count + filteredGifs.count) % filteredGifs.count] image];
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

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  [self renderBitmapInContext:cx size:size];
}

- (NSString *)tooltipName {
  return @"gifs";
}

@end
