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

#import "PHMirrorAnimation.h"

@implementation PHMirrorAnimation {
  PHMirrorAnimationType _type;
}

+ (id)animationWithType:(PHMirrorAnimationType)type {
  PHMirrorAnimation* animation = [self animation];
  animation->_type = type;
  return animation;
}

- (id)copyWithZone:(NSZone *)zone {
  PHMirrorAnimation* copy = [[self.class allocWithZone:zone] init];
  copy->_type = _type;
  return copy;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);

  PHMirrorAnimationType type = _type;
  NSInteger offset = (self.driver.isUserButton1Pressed ? 0x02 : 0x0) | (self.driver.isUserButton2Pressed ? 0x01 : 0x0);
  type = (type + offset) % PHMirrorAnimationType_Count;

  CGImageRef imageRef = CGBitmapContextCreateImage(cx);
  CGContextSetBlendMode(cx, kCGBlendModeCopy);

  if (type == PHMirrorAnimationTypeLeft) {
    CGContextScaleCTM(cx, -1, 1);
    CGContextTranslateCTM(cx, -size.width, 0);
    CGContextClipToRect(cx, CGRectMake(0, 0, size.width / 2, size.height));
    CGContextDrawImage(cx, CGRectMake(0, 0, size.width, size.height), imageRef);

  } else if (type == PHMirrorAnimationTypeRight) {
    CGContextScaleCTM(cx, -1, 1);
    CGContextTranslateCTM(cx, -size.width, 0);
    CGContextClipToRect(cx, CGRectMake(size.width / 2, 0, size.width / 2, size.height));
    CGContextDrawImage(cx, CGRectMake(0, 0, size.width, size.height), imageRef);

  } else if (type == PHMirrorAnimationTypeTop) {
    CGContextScaleCTM(cx, 1, -1);
    CGContextTranslateCTM(cx, 0, -size.height);
    CGContextClipToRect(cx, CGRectMake(0, 0, size.width, size.height / 2));
    CGContextDrawImage(cx, CGRectMake(0, 0, size.width, size.height), imageRef);

  } else if (type == PHMirrorAnimationTypeBottom) {
    CGContextScaleCTM(cx, 1, -1);
    CGContextTranslateCTM(cx, 0, -size.height);
    CGContextClipToRect(cx, CGRectMake(0, size.height / 2, size.width, size.height / 2));
    CGContextDrawImage(cx, CGRectMake(0, 0, size.width, size.height), imageRef);
  }
  CGImageRelease(imageRef);

  CGContextRestoreGState(cx);
}

- (NSString *)tooltipName {
  if (_type == PHMirrorAnimationTypeLeft) {
    return @"Mirror Left";
    
  } else if (_type == PHMirrorAnimationTypeRight) {
    return @"Mirror Right";
    
  } else if (_type == PHMirrorAnimationTypeTop) {
    return @"Mirror Top";
    
  } else if (_type == PHMirrorAnimationTypeBottom) {
    return @"Mirror Bottom";
  }

return nil;
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
