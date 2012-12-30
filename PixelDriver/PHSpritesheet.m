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

#import "PHSpritesheet.h"

#import "Utilities.h"

@interface PHSpritesheet()
@property (nonatomic, readonly) NSImage* image;
@end

@implementation PHSpritesheet

- (id)initWithName:(NSString *)name spriteSize:(CGSize)spriteSize {
  if ((self = [super init])) {
    NSString* filename = PHFilenameForResourcePath([[@"spritesheets" stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"png"]);
    _image = [[NSImage alloc] initWithData:[NSData dataWithContentsOfFile:filename]];
    if (nil == _image) {
      NSLog(@"Failed to load spritesheet at path: %@", filename);
      self = nil;
      return self;
    }

    _spriteSize = spriteSize;
    _numberOfSprites = CGSizeMake(_image.size.width / _spriteSize.width,
                                  _image.size.height / _spriteSize.height);
  }
  return self;
}

- (CGImageRef)imageAtX:(NSInteger)x y:(NSInteger)y {
  CGSize spriteSize = _spriteSize;
  CGContextRef cx = PHCreate8BitBitmapContextWithSize(spriteSize);

  CGContextSetInterpolationQuality(cx, kCGInterpolationNone);

  CGFloat offsetX = x * spriteSize.width;
  CGFloat offsetY = (_numberOfSprites.height - 1 - y) * spriteSize.height;

  CGContextScaleCTM(cx, 1, -1);
  CGContextTranslateCTM(cx, 0, -spriteSize.height);

  NSGraphicsContext* graphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:cx flipped:NO];
  [NSGraphicsContext setCurrentContext:graphicsContext];
  [_image drawInRect:CGRectMake(0, 0, spriteSize.width, spriteSize.height)
            fromRect:CGRectMake(offsetX, offsetY, spriteSize.width, spriteSize.height)
           operation:NSCompositeCopy
            fraction:1];

  CGImageRef imageRef = CGBitmapContextCreateImage(cx);
  CGContextRelease(cx);

  return imageRef;
}

@end

@interface PHSpriteAnimationFrame : NSObject
@property (nonatomic, assign) NSInteger x;
@property (nonatomic, assign) NSInteger y;
@property (nonatomic, assign) NSTimeInterval duration;
@end

@implementation PHSpriteAnimationFrame
@end

@implementation PHSpriteAnimation {
  PHSpritesheet* _spritesheet;
  NSMutableArray* _frames;

  BOOL _animating;
  NSTimeInterval _currentFrameAge;
  NSInteger _direction;

  NSTimeInterval _lastTick;
}

- (id)initWithSpritesheet:(PHSpritesheet *)spritesheet {
  if ((self = [super init])) {
    _spritesheet = spritesheet;
    _frames = [NSMutableArray array];
    _repeats = YES;
    _bounces = NO;
    _direction = 1;
    _animating = YES;
    _animationScale = 1;
  }
  return self;
}

- (void)addFrameAtX:(NSInteger)x y:(NSInteger)y duration:(NSTimeInterval)duration {
  PHSpriteAnimationFrame* frame = [[PHSpriteAnimationFrame alloc] init];
  frame.x = x;
  frame.y = y;
  frame.duration = duration;
  [_frames addObject:frame];

  _leftBoundary = 0;
  _rightBoundary = _frames.count - 1;
}

- (void)addStillFrameAtX:(NSInteger)x y:(NSInteger)y {
  [self addFrameAtX:x y:y duration:-1];
}

- (CGImageRef)imageRefAtCurrentTick {
  if (_frames.count == 0) {
    return nil;
  }
  PHSpriteAnimationFrame* frame = [_frames objectAtIndex:_currentFrameIndex];

  if (frame.duration >= 0 && _lastTick > 0) {
    NSTimeInterval delta = [NSDate timeIntervalSinceReferenceDate] - _lastTick;
    _currentFrameAge += delta * _animationScale;

    if (_animating && _currentFrameAge >= frame.duration) {
      [self advanceToNextAnimation];
      frame = [_frames objectAtIndex:_currentFrameIndex];
    }
  }

  _lastTick = [NSDate timeIntervalSinceReferenceDate];

  return [_spritesheet imageAtX:frame.x y:frame.y];
}

- (void)setCurrentFrameIndex:(NSInteger)frameIndex {
  _currentFrameIndex = frameIndex;
  _currentFrameAge = 0;
  _direction = 1;
}

- (void)advanceToNextAnimation {
  NSInteger nextFrame = _currentFrameIndex + _direction;

  if (nextFrame < _leftBoundary) {
    if (_bounces && _repeats) {
      nextFrame = _leftBoundary + 1;
      _direction = -_direction;
    } else {
      _animating = NO;
    }
  }

  if (nextFrame >= _rightBoundary + 1) {
    if (_bounces) {
      nextFrame = _rightBoundary - 1;
      _direction = -_direction;
    } else if (_repeats) {
      nextFrame = _leftBoundary;
    } else {
      _animating = NO;
    }
  }

  if (_animating) {
    _currentFrameIndex = nextFrame;
    PHSpriteAnimationFrame* frame = [_frames objectAtIndex:_currentFrameIndex];
    if (frame.duration >= 0) {
      _currentFrameAge = MIN(0.2, _currentFrameAge - frame.duration);
    } else {
      _currentFrameAge = 0;
    }
  }
}

- (BOOL)isCurrentFrameStill {
  PHSpriteAnimationFrame* frame = [_frames objectAtIndex:_currentFrameIndex];
  return frame.duration < 0;
}

@end
