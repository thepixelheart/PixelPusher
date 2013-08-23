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

#import "PHColorSpliceAnimation.h"

@implementation PHColorSpliceAnimation {
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
  CGContextSaveGState(cx);
  
  CGContextRef incomingContextRef = PHCreate8BitBitmapContextWithSize(CGSizeMake(size.width * 2, size.height * 2));
  CGImageRef incomingImageRef = CGBitmapContextCreateImage(cx);
  CGContextDrawImage(incomingContextRef, CGRectMake(0, 0, size.width * 2, size.height * 2), incomingImageRef);
  CGImageRelease(incomingImageRef);
  
  CGContextRef outgoingContextRef = PHCreate8BitBitmapContextWithSize(CGSizeMake(size.width * 2, size.height * 2));
  
  unsigned char* incomingData = (unsigned char *)CGBitmapContextGetData(incomingContextRef);
  unsigned char* outgoingData = (unsigned char *)CGBitmapContextGetData(outgoingContextRef);
  
  size_t bytesPerRow = CGBitmapContextGetBytesPerRow(incomingContextRef);
  
  for (NSInteger iy = 0; iy < size.height * 2; ++iy) {
    for (NSInteger ix = 0; ix < size.width * 2; ++ix) {
      NSInteger destinationOffset = ix * 4 + iy * bytesPerRow;
      NSInteger offset1 = MAX(0, MIN(size.width * 2, ix)) * 4 + iy * bytesPerRow;
      NSInteger offset2 = MAX(0, MIN(size.width * 2, (NSInteger)((CGFloat)ix - 2.f * self.bassDegrader.value))) * 4 + iy * bytesPerRow;
      NSInteger offset3 = MAX(0, MIN(size.width * 2, ix)) * 4 + MAX(0, MIN(size.height * 2, iy)) * bytesPerRow;

      outgoingData[destinationOffset + 0] = 0;
      outgoingData[destinationOffset + 1] = incomingData[offset2 + 1];
      outgoingData[destinationOffset + 2] = 0;
      outgoingData[destinationOffset + 3] = incomingData[destinationOffset + 3];
    }
  }
  CGContextRelease(incomingContextRef);
  
  CGImageRef imageRef = CGBitmapContextCreateImage(outgoingContextRef);
  CGRect rect = CGRectMake(-size.width / 2, -size.height / 2, size.width * 2, size.height * 2);
  CGContextClearRect(cx, rect);
  CGContextDrawImage(cx, rect, imageRef);
  CGImageRelease(imageRef);
  
  CGContextRelease(outgoingContextRef);
  CGContextRestoreGState(cx);
}

- (BOOL)isPipeAnimation {
  return YES;
}

- (NSString *)tooltipName {
  return @"Color Splice";
}

- (NSImage *)previewImage {
  return nil;
}

- (NSArray *)categories {
  return @[
           PHAnimationCategoryPipes
           ];
}

@end
