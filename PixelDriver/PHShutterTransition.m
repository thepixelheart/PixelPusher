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

#import "PHShutterTransition.h"

@implementation PHShutterTransition

- (void)renderBitmapInContext:(CGContextRef)cx
                         size:(CGSize)size
                  leftContext:(CGContextRef)leftContext
                 rightContext:(CGContextRef)rightContext
                            t:(CGFloat)t {
  CGRect frame = CGRectMake(0, 0, size.width, size.height);
  CGContextSaveGState(cx);
  const NSInteger numberOfRects = 8;
  CGFloat rectWidth = size.width / numberOfRects;
  if (nil != leftContext) {
    CGContextSaveGState(cx);
    CGImageRef leftImage = CGBitmapContextCreateImage(leftContext);
    CGFloat shutterWidth = rectWidth * (1 - t);
    CGRect rects[numberOfRects] = {
      {(rectWidth - shutterWidth), 0, shutterWidth, size.height},
      {(rectWidth - shutterWidth) + rectWidth, 0, shutterWidth, size.height},
      {(rectWidth - shutterWidth) + rectWidth * 2, 0, shutterWidth, size.height},
      {(rectWidth - shutterWidth) + rectWidth * 3, 0, shutterWidth, size.height},
      {(rectWidth - shutterWidth) + rectWidth * 4, 0, shutterWidth, size.height},
      {(rectWidth - shutterWidth) + rectWidth * 5, 0, shutterWidth, size.height},
      {(rectWidth - shutterWidth) + rectWidth * 6, 0, shutterWidth, size.height},
      {(rectWidth - shutterWidth) + rectWidth * 7, 0, shutterWidth, size.height},
    };
    CGContextClipToRects(cx, rects, numberOfRects);
    CGContextDrawImage(cx, frame, leftImage);
    CGImageRelease(leftImage);
    CGContextRestoreGState(cx);
  }
  if (nil != rightContext) {
    CGContextSaveGState(cx);
    CGImageRef rightImage = CGBitmapContextCreateImage(rightContext);
    CGFloat shutterWidth = rectWidth * t;
    CGRect rects[numberOfRects] = {
      {0, 0, shutterWidth, size.height},
      {rectWidth, 0, shutterWidth, size.height},
      {rectWidth * 2, 0, shutterWidth, size.height},
      {rectWidth * 3, 0, shutterWidth, size.height},
      {rectWidth * 4, 0, shutterWidth, size.height},
      {rectWidth * 5, 0, shutterWidth, size.height},
      {rectWidth * 6, 0, shutterWidth, size.height},
      {rectWidth * 7, 0, shutterWidth, size.height},
    };
    CGContextClipToRects(cx, rects, numberOfRects);
    CGContextDrawImage(cx, frame, rightImage);
    CGImageRelease(rightImage);
    CGContextRestoreGState(cx);
  }

  CGContextRestoreGState(cx);
}

- (NSString *)tooltipName {
  return @"Shutter";
}

@end
