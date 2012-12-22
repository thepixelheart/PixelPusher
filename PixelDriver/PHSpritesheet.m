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
  NSInteger _currentFrame;
  NSTimeInterval _nextFrameTick;
  NSInteger _direction;
}

- (id)initWithSpritesheet:(PHSpritesheet *)spritesheet {
  if ((self = [super init])) {
    _spritesheet = spritesheet;
    _frames = [NSMutableArray array];
    _repeats = YES;
    _bounces = NO;
    _direction = 1;
    _animating = YES;
  }
  return self;
}

- (void)addFrameAtX:(NSInteger)x y:(NSInteger)y duration:(NSTimeInterval)duration {
  PHSpriteAnimationFrame* frame = [[PHSpriteAnimationFrame alloc] init];
  frame.x = x;
  frame.y = y;
  frame.duration = duration;
  [_frames addObject:frame];
}

- (CGImageRef)imageRefAtCurrentTick {
  if (_frames.count == 0) {
    return nil;
  }
  PHSpriteAnimationFrame* frame = [_frames objectAtIndex:_currentFrame];

  if (_nextFrameTick == 0) {
    _nextFrameTick = [NSDate timeIntervalSinceReferenceDate] + frame.duration;
  }
  if (_animating
      && _nextFrameTick > 0 && [NSDate timeIntervalSinceReferenceDate] >= _nextFrameTick) {
    NSInteger nextFrame = _currentFrame + _direction;

    if (nextFrame < 0) {
      if (_bounces && _repeats) {
        nextFrame = 1;
        _direction = -_direction;
      } else {
        _animating = NO;
      }
    }
    if (nextFrame >= _frames.count) {
      if (_bounces) {
        nextFrame = _frames.count - 2;
        _direction = -_direction;
      } else if (_repeats) {
        nextFrame = 0;
      } else {
        _animating = NO;
      }
    }
    if (_animating) {
      _currentFrame = nextFrame;
      frame = [_frames objectAtIndex:_currentFrame];
      _nextFrameTick = [NSDate timeIntervalSinceReferenceDate] + frame.duration;
    }
  }

  CGSize spriteSize = _spritesheet.spriteSize;
  CGContextRef cx = PHCreate8BitBitmapContextWithSize(spriteSize);

  CGContextSetInterpolationQuality(cx, kCGInterpolationNone);

  CGFloat x = frame.x * spriteSize.width;
  CGFloat y = frame.y * spriteSize.height;

  CGContextScaleCTM(cx, 1, -1);
  CGContextTranslateCTM(cx, 0, -spriteSize.height);

  NSGraphicsContext* graphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:cx flipped:NO];
  [NSGraphicsContext setCurrentContext:graphicsContext];
  [_spritesheet.image drawInRect:CGRectMake(0, 0, spriteSize.width, spriteSize.height)
                        fromRect:CGRectMake(x, y, spriteSize.width, spriteSize.height)
                       operation:NSCompositeCopy
                        fraction:1];

  CGImageRef imageRef = CGBitmapContextCreateImage(cx);
  CGContextRelease(cx);

  return imageRef;
}

@end
