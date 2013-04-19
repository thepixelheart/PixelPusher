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

#import "PHProcessingAnimation.h"

#import "PHProcessingSource.h"

@implementation PHProcessingAnimation

+ (id)animationWithSource:(PHProcessingSource *)source {
  PHProcessingAnimation* animation = [super animation];
  animation.source = source;
  return animation;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);
  CGContextScaleCTM(cx, 1, -1);
  CGContextTranslateCTM(cx, 0, -size.height);
  [_source drawImageInContext:cx size:size];
  CGContextRestoreGState(cx);
}

- (NSString *)tooltipName {
  return _source.name;
}

@end
