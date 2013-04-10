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

#import "PHResetAnimation.h"

@implementation PHResetAnimation

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGAffineTransform transform = CGContextGetCTM(cx);
  transform = CGAffineTransformInvert(transform);
  CGContextConcatCTM(cx, transform);
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  // Render an X
  CGContextSetRGBStrokeColor(cx, 1, 1, 1, 1);
  CGContextSetLineWidth(cx, 5);
  CGContextMoveToPoint(cx, size.width / 4, size.height / 4);
  CGContextAddLineToPoint(cx, size.width * 3 / 4, size.height * 3 / 4);
  CGContextMoveToPoint(cx, size.width * 3 / 4, size.height / 4);
  CGContextAddLineToPoint(cx, size.width / 4, size.height * 3 / 4);
  CGContextStrokePath(cx);
}

- (NSString *)tooltipName {
  return @"Reset";
}

- (BOOL)isPipeAnimation {
  return YES;
}

- (NSArray *)categories {
  return @[
    PHAnimationCategoryPipes
  ];
}

@end
