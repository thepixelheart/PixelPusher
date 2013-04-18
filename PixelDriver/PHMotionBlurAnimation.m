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

#import "PHMotionBlurAnimation.h"

@implementation PHMotionBlurAnimation {
  CGImageRef _imageOfPreviousFrame;
}

- (void)dealloc {
  if (nil != _imageOfPreviousFrame) {
    CGImageRelease(_imageOfPreviousFrame);
  }
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);
  CGContextTranslateCTM(cx, size.width / 2, size.height / 2);

  if (_imageOfPreviousFrame) {
    CGContextSaveGState(cx);
    CGContextSetAlpha(cx, 0.95);
    CGContextTranslateCTM(cx, -size.width / 2, -size.height / 2);
    CGRect imageRect = CGRectMake(-size.width / 2, -size.height / 2, size.width * 2, size.height * 2);
    CGContextDrawImage(cx, imageRect, _imageOfPreviousFrame);
    CGContextRestoreGState(cx);
  }

  CGContextTranslateCTM(cx, -size.width / 2, -size.height / 2);

  if (nil != _imageOfPreviousFrame) {
    CGImageRelease(_imageOfPreviousFrame);
  }
  _imageOfPreviousFrame = CGBitmapContextCreateImage(cx);
  CGContextRestoreGState(cx);
}

- (BOOL)isPipeAnimation {
  return YES;
}

- (NSImage *)previewImage {
  return [NSImage imageNamed:@"motionblur"];
}

- (NSString *)tooltipName {
  return @"Motion Blur";
}

- (NSArray *)categories {
  return @[
           PHAnimationCategoryPipes
           ];
}

@end
