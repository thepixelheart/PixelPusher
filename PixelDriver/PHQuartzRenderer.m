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

#import "PHQuartzRenderer.h"

@implementation PHQuartzRenderer

- (id)init {
  return [self initWithCompositionPath:nil pixelsWide:0 pixelsHigh:0];
}

- (NSBitmapImageRep *)bitmapImageForTime:(NSTimeInterval)time {
  if (![_renderer renderAtTime:time arguments:nil]) {
    return nil;
  }

  return [_renderer createSnapshotImageOfType:@"NSBitmapImageRep"];
}

- (id)initWithCompositionPath:(NSString*)path pixelsWide:(CGFloat)width pixelsHigh:(CGFloat)height {
  //Check parameters - Rendering at sizes smaller than 16x16 will likely produce garbage
  if (![path length] || (width < 16) || (height < 16)) {
    self = nil;
    return nil;
  }

  if (self = [super init]) {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);

    QCComposition* composition = [QCComposition compositionWithFile:path];
    if (nil != composition) {
      _renderer = [[QCRenderer alloc] initOffScreenWithSize:NSMakeSize(width, height)
                                                 colorSpace:colorSpace
                                                composition:composition];
    }
    CGColorSpaceRelease(colorSpace);
    if (_renderer == nil) {
      self = nil;
      return nil;
    }
  }
  
  return self;
}

@end
