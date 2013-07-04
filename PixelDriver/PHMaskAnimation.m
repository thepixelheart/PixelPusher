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

#import "PHMaskAnimation.h"

CGImageRef createMaskWithImage(CGImageRef image)
{
  size_t maskWidth               = CGImageGetWidth(image);
  size_t maskHeight              = CGImageGetHeight(image);
  //  round bytesPerRow to the nearest 16 bytes, for performance's sake
  size_t bytesPerRow             = (maskWidth + 15) & 0xfffffff0;
  size_t bufferSize              = bytesPerRow * maskHeight;

  //  allocate memory for the bits
  CFMutableDataRef dataBuffer = CFDataCreateMutable(kCFAllocatorDefault, 0);
  CFDataSetLength(dataBuffer, bufferSize);

  //  the data will be 8 bits per pixel, no alpha
  CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceGray();
  CGContextRef ctx            = CGBitmapContextCreate(CFDataGetMutableBytePtr(dataBuffer),
                                                      maskWidth, maskHeight,
                                                      8, bytesPerRow, colourSpace, kCGImageAlphaNone);
  //  drawing into this context will draw into the dataBuffer.
  CGContextDrawImage(ctx, CGRectMake(0, 0, maskWidth, maskHeight), image);

  unsigned char* data = (unsigned char *)CGBitmapContextGetData(ctx);
  size_t bytesPerRowCtx = CGBitmapContextGetBytesPerRow(ctx);

  for (NSInteger iy = 0; iy < kWallHeight * 2; ++iy) {
    for (NSInteger ix = 0; ix < kWallWidth * 2; ++ix) {
      NSInteger offset = ix + iy * bytesPerRowCtx;

      data[offset] = 255 - data[offset];
    }
  }
  
  CGContextRelease(ctx);

  //  now make a mask from the data.
  CGDataProviderRef dataProvider  = CGDataProviderCreateWithCFData(dataBuffer);
  CGImageRef mask                 = CGImageMaskCreate(maskWidth, maskHeight, 8, 8, bytesPerRow,
                                                      dataProvider, NULL, FALSE);

  CGDataProviderRelease(dataProvider);
  CGColorSpaceRelease(colourSpace);
  CFRelease(dataBuffer);

  return mask;
}

@implementation PHMaskAnimation

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  // Create a mask of whatever's currently drawn.
  CGImageRef imageRef = CGBitmapContextCreateImage(cx);
  CGImageRef maskRef = createMaskWithImage(imageRef);
  CGImageRelease(imageRef);

  // Clear what's currently drawn.
  CGContextClearRect(cx, CGRectMake(0, 0, size.width, size.height));

  // Mask with this image.
  CGContextClipToMask(cx, CGRectMake(-size.width / 2, -size.height / 2, size.width * 2, size.height * 2), maskRef);
  CGImageRelease(maskRef);
}

- (BOOL)isPipeAnimation {
  return YES;
}

- (NSString *)tooltipName {
  return @"Mask";
}

- (NSArray *)categories {
  return @[
           PHAnimationCategoryPipes
           ];
}

@end
