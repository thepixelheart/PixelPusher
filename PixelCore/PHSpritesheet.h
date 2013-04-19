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

#import <Foundation/Foundation.h>

@interface PHSpritesheet : NSObject

- (id)initWithName:(NSString *)name spriteSize:(CGSize)spriteSize;

@property (nonatomic, readonly) CGSize spriteSize;
@property (nonatomic, readonly) CGSize numberOfSprites;

- (CGImageRef)imageAtX:(NSInteger)x y:(NSInteger)y;

@end

@interface PHSpriteAnimation : NSObject

- (id)initWithSpritesheet:(PHSpritesheet *)spritesheet;
- (void)addFrameAtX:(NSInteger)x y:(NSInteger)y duration:(NSTimeInterval)duration;

// When this frame is shown it will only change when advanceToNextAnimation is
// explicitly called.
- (void)addStillFrameAtX:(NSInteger)x y:(NSInteger)y;

- (CGImageRef)imageRefAtCurrentTick;

@property (nonatomic, assign) BOOL repeats; // Default: YES
@property (nonatomic, assign) BOOL bounces; // Default: NO

@property (nonatomic, assign) NSInteger leftBoundary; // Default: 0
@property (nonatomic, assign) NSInteger rightBoundary; // Default: count - 1

@property (nonatomic, assign) CGFloat animationScale; // Default: 1

@property (nonatomic, assign) NSInteger currentFrameIndex;

@property (nonatomic, readonly) BOOL isCurrentFrameStill;

// Forcefully move to the next frame in the animation.
- (void)advanceToNextAnimation;

@end
