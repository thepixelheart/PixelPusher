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

#import "PHTrippyTunnelAnimation.h"

@implementation PHTrippyTunnelAnimation {
  CGImageRef _imageOfPreviousFrame;
  CGFloat _scaleAdvance;
  CGFloat _rotationAdvance;
  CGFloat _centerAdvance;
}

- (void)dealloc {
  if (nil != _imageOfPreviousFrame) {
    CGImageRelease(_imageOfPreviousFrame);
  }
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  _rotationAdvance += self.secondsSinceLastTick * 0.01;
  _scaleAdvance += self.secondsSinceLastTick * 0.5;
  _centerAdvance += self.secondsSinceLastTick * 0.1;

  CGContextSaveGState(cx);
  CGContextTranslateCTM(cx, size.width / 2, size.height / 2);
  CGContextRotateCTM(cx, _rotationAdvance);

  CGFloat scale = cos(_scaleAdvance) * 0.1 + 1;
  CGContextScaleCTM(cx, scale, scale);

  if (_imageOfPreviousFrame) {
    CGContextSaveGState(cx);
    CGContextSetAlpha(cx, 0.9);
    CGContextTranslateCTM(cx, -size.width / 2, -size.height / 2);
    CGRect imageRect = CGRectMake(-size.width / 2 + cos(_centerAdvance * 3) * 1, -size.height / 2 + sin(_centerAdvance * 7) * 1, size.width * 2, size.height * 2);
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

- (NSString *)tooltipName {
  return @"Trippy Tunnel";
}

- (NSImage *)previewImage {
  return [NSImage imageNamed:@"trippytunnel"];
}

- (NSArray *)categories {
  return @[
           PHAnimationCategoryPipes
           ];
}

@end
