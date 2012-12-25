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

#import "PHBitmapPipeline.h"

#import "Utilities.h"

@interface PHBitmapRenderOperation : NSOperation
- (id)initWithBlock:(PHBitmapRenderBlock)block imageSize:(CGSize)size;
- (CGImageRef)renderedImage;
@end

@implementation PHBitmapRenderOperation {
  PHBitmapRenderBlock _block;
  CGSize _imageSize;
  CGImageRef _renderedImage;
}

- (id)initWithBlock:(PHBitmapRenderBlock)block imageSize:(CGSize)size {
  if ((self = [super init])) {
    _block = [block copy];
    _imageSize = size;
  }
  return self;
}

- (void)main {
  CGContextRef cx = PHCreate8BitBitmapContextWithSize(_imageSize);

  _block(cx, _imageSize);

  _renderedImage = CGBitmapContextCreateImage(cx);
  CGContextRelease(cx);
}

- (CGImageRef)renderedImage {
  return _renderedImage;
}

@end

@implementation PHBitmapPipeline {
  NSOperationQueue* _queue;
}

- (id)init {
  if ((self = [super init])) {
    _queue = [[NSOperationQueue alloc] init];
    _queue.maxConcurrentOperationCount = 1;
  }
  return self;
}

- (void)queueRenderBlock:(PHBitmapRenderBlock)block imageSize:(CGSize)size delegate:(id<PHBitmapReceiver>)delegate priority:(double)priority {
  NSArray* operations = [_queue.operations copy];
  for (NSOperation* op in operations) {
    if (op != [operations objectAtIndex:0]) {
      [op cancel];
    }
  }

  PHBitmapRenderOperation* op = [[PHBitmapRenderOperation alloc] initWithBlock:block imageSize:size];
  op.threadPriority = priority;
  __weak PHBitmapRenderOperation* weakOp = op;
  op.completionBlock = ^() {
    if (weakOp.isCancelled) {
      return;
    }

    CGImageRef imageRef = weakOp.renderedImage;
    dispatch_async(dispatch_get_main_queue(), ^{
      [delegate bitmapDidFinishRendering:imageRef];
      CGImageRelease(imageRef);
    });
  };
  [_queue addOperation:op];
}

@end
