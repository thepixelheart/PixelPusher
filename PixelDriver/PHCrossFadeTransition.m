//
// Copyright 2012-2013 Jeff Verkoeyen
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

#import "PHCrossFadeTransition.h"

@implementation PHCrossFadeTransition

- (void)renderBitmapInContext:(CGContextRef)cx
                         size:(CGSize)size
                  leftContext:(CGContextRef)leftContext
                 rightContext:(CGContextRef)rightContext
                            t:(CGFloat)t {
  CGRect frame = CGRectMake(0, 0, size.width, size.height);
  CGContextSaveGState(cx);

  if (nil != leftContext) {
    CGImageRef leftImage = CGBitmapContextCreateImage(leftContext);
    CGContextSetAlpha(cx, 1 - t);
    CGContextDrawImage(cx, frame, leftImage);
    CGImageRelease(leftImage);
  }
  if (nil != rightContext) {
    CGImageRef rightImage = CGBitmapContextCreateImage(rightContext);
    CGContextSetAlpha(cx, t);
    CGContextDrawImage(cx, frame, rightImage);
    CGImageRelease(rightImage);
  }

  CGContextRestoreGState(cx);
}

- (NSString *)tooltipName {
  return @"Cross Fade";
}

@end
