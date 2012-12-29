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

#import "PHProcessingSource.h"

@implementation PHProcessingSource {
  CGImageRef _imageRef;
}

- (void)dealloc {
  if (nil != _imageRef) {
    CGImageRelease(_imageRef);
  }
}

- (void)drawImageInContext:(CGContextRef)cx size:(CGSize)size {
  @synchronized(self) {
    if (nil != _imageRef) {
      CGContextDrawImage(cx, CGRectMake(0, 0, size.width, size.height), _imageRef);
    }
  }
}

- (void)updateImageWithContextRef:(CGContextRef)contextRef {
  @synchronized(self) {
    if (nil != _imageRef) {
      CGImageRelease(_imageRef);
    }
    _imageRef = CGBitmapContextCreateImage(contextRef);
  }
}

@end
