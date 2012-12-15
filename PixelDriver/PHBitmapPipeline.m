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

@interface PHBitmapRenderOperation : NSOperation
- (id)initWithBlock:(PHBitmapRenderBlock)block imageSize:(CGSize)size;
@end

@implementation PHBitmapRenderOperation {
  PHBitmapRenderBlock _block;
  CGSize _imageSize;
}

- (id)initWithBlock:(PHBitmapRenderBlock)block imageSize:(CGSize)size {
  if ((self = [super init])) {
    _block = [block copy];
    _imageSize = size;
  }
  return self;
}

- (void)main {

}

@end

@implementation PHBitmapPipeline

- (void)queueRenderBlock:(PHBitmapRenderBlock)block imageSize:(CGSize)size {
  
}

@end
