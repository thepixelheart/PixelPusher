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

#import "PHBoxBlurFilter.h"

#import <QuartzCore/CoreImage.h>

@implementation PHBoxBlurFilter

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);

  CGImageRef currentImageRef = CGBitmapContextCreateImage(cx);
  CIImage *image = [CIImage imageWithCGImage:currentImageRef];
  CGImageRelease(currentImageRef);

  CIFilter *filter = [CIFilter filterWithName:@"CIBoxBlur"
                                keysAndValues:
                      kCIInputImageKey, image,
                      kCIInputRadiusKey, @(self.bassDegrader.value * 10),
                      nil];

  CIImage *result = [filter valueForKey:kCIOutputImageKey];
  CGRect frame = CGRectMake(0, 0, size.width, size.height);
  CGRect sourceFrame = CGRectMake(size.width / 2, size.height / 2, size.width, size.height);

  NSGraphicsContext* previousContext = [NSGraphicsContext currentContext];
  NSGraphicsContext* graphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:cx flipped:NO];
  [NSGraphicsContext setCurrentContext:graphicsContext];
  [result drawInRect:frame fromRect:sourceFrame operation:NSCompositeCopy fraction:1];
  [NSGraphicsContext setCurrentContext:previousContext];

  CGContextRestoreGState(cx);
}

- (BOOL)isPipeAnimation {
  return YES;
}

- (NSArray *)categories {
  return @[
           PHAnimationCategoryFilters,
           PHAnimationCategoryPipes
           ];
}

- (NSString *)tooltipName {
  return @"Box Blur Filter";
}

@end
