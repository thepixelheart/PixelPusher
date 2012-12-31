//
// Copyright 2012, 2013 Josh Avant
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

// Based on the limited edition Daft Punk coffee table sold by Habitat a few years ago:
// http://www.youtube.com/watch?v=zCA79Du-WqY

#import "PHDaftPixelAnimation.h"

static const CGFloat kPHDaftPixelAnimationAmplitudeThreshold = 0.125;
static const CGFloat kPHDaftPixelAnimationTimeDeltaThreshold = 0.125;

// Animation Frame Abstraction
@interface PHDaftPixelAnimationFrame : NSObject
+ (id)frame;
- (void)drawFrameInContext:(CGContextRef)context size:(CGSize)size; // subclasses will implement this
@end

@implementation PHDaftPixelAnimationFrame
+ (id)frame { return [[self alloc] init]; }
- (void)drawFrameInContext:(CGContextRef)context size:(CGSize)size {} // do nothing
@end


// ANIMATION FRAMES
// Squares
@interface PHDaftPixelAnimationFrameRectInCorners : PHDaftPixelAnimationFrame
@end
@implementation PHDaftPixelAnimationFrameRectInCorners
- (void)drawFrameInContext:(CGContextRef)context size:(CGSize)size
{
  CGFloat rectWidth = ceil(size.width / 2.5);
  CGFloat rectHeight = ceil(size.height / 2.5);
  
  CGRect topLeft = CGRectMake(0.f, 0.f, rectWidth, rectHeight);
  CGRect topRight = CGRectMake(size.width - rectWidth, 0.f, rectWidth, rectHeight);
  CGRect bottomRight = CGRectMake(size.width - rectWidth, size.height - rectHeight, rectWidth, rectHeight);
  CGRect bottomLeft = CGRectMake(0.f, size.height - rectHeight, rectWidth, rectHeight);
  
  CGContextFillRects(context, (CGRect []){topLeft, topRight, bottomRight, bottomLeft}, 4);
}
@end

@interface PHDaftPixelAnimationFrameRectOnLeftAndRight : PHDaftPixelAnimationFrame
@end
@implementation PHDaftPixelAnimationFrameRectOnLeftAndRight
- (void)drawFrameInContext:(CGContextRef)context size:(CGSize)size
{
  CGFloat rectWidth = ceil(size.width / 2.5);
  CGFloat rectHeight = ceil(size.height / 1.8);
  
  CGFloat yOffset = (size.height - rectHeight) / 2;
  
  CGRect left = CGRectMake(0.f, yOffset, rectWidth, rectHeight);
  CGRect right = CGRectMake(size.width - rectWidth, yOffset, rectWidth, rectHeight);
  
  CGContextFillRects(context, (CGRect []){left, right}, 2);
}
@end

@interface PHDaftPixelAnimationFrameRectInCenter : PHDaftPixelAnimationFrame
@end
@implementation PHDaftPixelAnimationFrameRectInCenter
- (void)drawFrameInContext:(CGContextRef)context size:(CGSize)size
{
  CGFloat rectWidth = ceil(size.width / 1.75);
  CGFloat rectHeight = ceil(size.height / 1.8);
  
  CGRect centerBlock = CGRectMake((size.width - rectWidth) / 2, (size.height - rectHeight) / 2, rectWidth, rectHeight);
  
  CGContextFillRect(context, centerBlock);
}
@end

@interface PHDaftPixelAnimationFrameRectOnTopAndBottom : PHDaftPixelAnimationFrame
@end
@implementation PHDaftPixelAnimationFrameRectOnTopAndBottom
- (void)drawFrameInContext:(CGContextRef)context size:(CGSize)size
{
  CGFloat rectWidth = ceil(size.width / 1.75);
  CGFloat rectHeight = ceil(size.height / 2.5);
  
  CGFloat xOffset = (size.width - rectWidth) / 2;
  
  CGRect top = CGRectMake(xOffset, 0.f, rectWidth, rectHeight);
  CGRect bottom = CGRectMake(xOffset, size.height - rectHeight, rectWidth, rectHeight);
  
  CGContextFillRects(context, (CGRect []){top, bottom}, 2);
}
@end

@interface PHDaftPixelAnimationFrameRectAroundEdges : PHDaftPixelAnimationFrame
@end
@implementation PHDaftPixelAnimationFrameRectAroundEdges
- (void)drawFrameInContext:(CGContextRef)context size:(CGSize)size
{
  CGFloat columnWidth = ceil(size.width / 8.f);
  CGFloat rowHeight = ceil(size.height / 8.f);
  
  CGFloat blockWidth = 2 * columnWidth;
  CGFloat blockHeight = 2 * rowHeight;
  
  CGRect topLeft = CGRectMake(0.f, 0.f, blockWidth, blockHeight);
  CGRect topCenter = CGRectMake(blockWidth + columnWidth, 0.f, blockWidth, blockHeight);
  CGRect topRight = CGRectMake(2 * (blockWidth + columnWidth), 0.f, blockWidth, blockHeight);
  CGRect centerRight = CGRectMake(2 * (blockWidth + columnWidth), blockHeight + rowHeight, blockWidth, blockHeight);
  CGRect bottomRight = CGRectMake(2 * (blockWidth + columnWidth), 2 * (blockHeight + rowHeight), blockWidth, blockHeight);
  CGRect bottomCenter = CGRectMake(blockWidth + columnWidth, 2 * (blockHeight + rowHeight), blockWidth, blockHeight);
  CGRect bottomLeft = CGRectMake(0.f, 2 * (blockHeight + rowHeight), blockWidth, blockHeight);
  CGRect centerLeft = CGRectMake(0.f, blockHeight + rowHeight, blockWidth, blockHeight);
  
  CGContextFillRects(context, (CGRect []){topLeft, topCenter, topRight, centerRight, bottomRight, bottomCenter, bottomLeft, centerLeft}, 8);
}
@end

@interface PHDaftPixelAnimationFrameEightRightHead : PHDaftPixelAnimationFrame
@end
@implementation PHDaftPixelAnimationFrameEightRightHead
- (void)drawFrameInContext:(CGContextRef)context size:(CGSize)size
{
  CGFloat columnWidth = ceil(size.width / 8.f);
  CGFloat rowHeight = ceil(size.height / 8.f);
  
  CGFloat blockWidth = 2 * columnWidth;
  CGFloat blockHeight = 2 * rowHeight;
  
  CGRect topLeft = CGRectMake(0.f, 0.f, blockWidth, blockHeight);
  CGRect topCenter = CGRectMake(blockWidth + columnWidth, 0.f, blockWidth, blockHeight);
  CGRect topRight = CGRectMake(2 * (blockWidth + columnWidth), 0.f, blockWidth, blockHeight);
  CGRect centerRight = CGRectMake(2 * (blockWidth + columnWidth), blockHeight + rowHeight, blockWidth, blockHeight);
  CGRect bottomRight = CGRectMake(2 * (blockWidth + columnWidth), 2 * (blockHeight + rowHeight), blockWidth, blockHeight);
  CGRect bottomCenter = CGRectMake(blockWidth + columnWidth, 2 * (blockHeight + rowHeight), blockWidth, blockHeight);
  CGRect bottomLeft = CGRectMake(0.f, 2 * (blockHeight + rowHeight), blockWidth, blockHeight);
  CGRect centerLeft = CGRectMake(0.f, blockHeight + rowHeight, blockWidth, blockHeight);
  
  CGContextFillRects(context, (CGRect []){topLeft, topCenter, topRight, centerRight, bottomRight, bottomCenter, bottomLeft, centerLeft}, 8);
}
@end


@interface PHDaftPixelAnimation ()

+ (NSArray *)allSequences;
- (void)populateFrameQueue;
- (PHDaftPixelAnimationFrame *)nextFrame;

@end

@implementation PHDaftPixelAnimation{
  NSArray*                   _sequences;
  NSMutableArray*            _frameQueue;
  PHDaftPixelAnimationFrame* _currentFrame;
  
  NSTimeInterval _lastFrameUpdate;
  CGFloat _lastSubBassAmplitude;
  CGFloat _lastSnareAmplitude;
  CGFloat _lastVocalAmplitude;
}

- (id)init {
  if ((self = [super init]))
  {
    _frameQueue = [NSMutableArray array];
    [self populateFrameQueue];
    
    _currentFrame = [self nextFrame];
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  if (self.driver.unifiedSpectrum)
  {
    if(_frameQueue.count == 0) { [self populateFrameQueue]; }
    
    NSTimeInterval timeDelta      = [NSDate timeIntervalSinceReferenceDate] - _lastFrameUpdate;
    CGFloat subBassAmplitudeDelta = self.driver.subBassAmplitude - _lastSubBassAmplitude;
    CGFloat snareAmplitudeDelta   = self.driver.snareAmplitude - _lastSnareAmplitude;
    CGFloat vocalAmplitudeDelta   = self.driver.vocalAmplitude - _lastVocalAmplitude;
    
    if ((snareAmplitudeDelta   > kPHDaftPixelAnimationAmplitudeThreshold ||
         subBassAmplitudeDelta > kPHDaftPixelAnimationAmplitudeThreshold ||
         vocalAmplitudeDelta   > kPHDaftPixelAnimationAmplitudeThreshold) &&
        timeDelta > kPHDaftPixelAnimationTimeDeltaThreshold)
    {
      _currentFrame = [self nextFrame];
      _lastFrameUpdate = [NSDate timeIntervalSinceReferenceDate];
    }
    
    CGColorRef frameColor = CGColorRetain([NSColor redColor].CGColor);
    CGContextSetStrokeColorWithColor(cx, frameColor);
    CGContextSetFillColorWithColor(cx, frameColor);
    
    [_currentFrame drawFrameInContext:cx size:size];
    
    _lastSnareAmplitude   = self.driver.snareAmplitude;
    _lastSubBassAmplitude = self.driver.subBassAmplitude;
    _lastVocalAmplitude   = self.driver.vocalAmplitude;
    CGColorRelease(frameColor);

  }
}

+ (NSArray *)allSequences
{
  NSArray *squares = @[[PHDaftPixelAnimationFrameRectInCorners frame],
                       [PHDaftPixelAnimationFrameRectOnLeftAndRight frame],
                       [PHDaftPixelAnimationFrameRectInCenter frame],
                       [PHDaftPixelAnimationFrameRectOnTopAndBottom frame],
                       [PHDaftPixelAnimationFrameRectInCorners frame],
                       [PHDaftPixelAnimationFrameRectAroundEdges frame]];
  
  return @[squares];
}

- (void)populateFrameQueue
{
  NSArray *allSequences = [PHDaftPixelAnimation allSequences];
  [_frameQueue addObjectsFromArray:[allSequences objectAtIndex:arc4random_uniform((u_int32_t)allSequences.count)]];
}

- (PHDaftPixelAnimationFrame *)nextFrame
{
  PHDaftPixelAnimationFrame *frame = _frameQueue[0];
  [_frameQueue removeObjectAtIndex:0];
  return frame;
}

- (NSString *)tooltipName {
  return @"Daft Pixel";
}

@end
