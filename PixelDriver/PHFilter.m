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

#import "PHFilter.h"

#import "PHSystem.h"
#import <QuartzCore/CoreImage.h>

@implementation PHFilter

- (NSString *)filterName {
  return nil;
}

- (id)wallCenterValue {
  return [self useCroppedImage] ? [CIVector vectorWithX:kWallWidth / 2 Y:kWallHeight / 2] : [CIVector vectorWithX:kWallWidth Y:kWallHeight];
}

- (id)radiusValue {
  return nil;
}

- (id)centerValue {
  return nil;
}

- (id)angleValue {
  return nil;
}

- (id)widthValue {
  return nil;
}

- (id)sharpnessValue {
  return nil;
}

- (id)zoomValue {
  return nil;
}

- (id)rotationValue {
  return nil;
}

- (id)periodicityValue {
  return nil;
}

- (id)insetPoint0Value {
  return nil;
}

- (id)insetPoint1Value {
  return nil;
}

- (id)strandsValue {
  return nil;
}

- (id)intensityValue {
  return nil;
}

- (id)evValue {
  return nil;
}

- (CIImage *)imageValueWithContext:(CGContextRef)cx {
  CGImageRef currentImageRef = CGBitmapContextCreateImage(cx);
  if ([self useCroppedImage]) {
    CGContextRef croppedContextRef = [[PHSystem class] createWallContext];
    CGContextDrawImage(croppedContextRef, CGRectMake(-kWallWidth / 2, -kWallHeight / 2, kWallWidth * 2, kWallHeight * 2), currentImageRef);
    CGImageRelease(currentImageRef);

    currentImageRef = CGBitmapContextCreateImage(croppedContextRef);
    CGContextRelease(croppedContextRef);
  }
  CIImage *image = [CIImage imageWithCGImage:currentImageRef];
  CGImageRelease(currentImageRef);
  return image;
}

- (BOOL)useCroppedImage {
  return NO;
}

- (void)storeValue:(id)value forKey:(NSString *)key inFilter:(CIFilter *)filter {
  if (nil != value) {
    [filter setValue:value forKey:key];
  }
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);

  CIFilter *filter = [CIFilter filterWithName:[self filterName]];
  [self storeValue:[self imageValueWithContext:cx] forKey:kCIInputImageKey inFilter:filter];
  [self storeValue:[self angleValue] forKey:kCIInputAngleKey inFilter:filter];
  [self storeValue:[self centerValue] forKey:kCIInputCenterKey inFilter:filter];
  [self storeValue:[self evValue] forKey:kCIInputEVKey inFilter:filter];
  [self storeValue:[self insetPoint0Value] forKey:@"inputInsetPoint0" inFilter:filter];
  [self storeValue:[self insetPoint1Value] forKey:@"inputInsetPoint1" inFilter:filter];
  [self storeValue:[self intensityValue] forKey:kCIInputIntensityKey inFilter:filter];
  [self storeValue:[self periodicityValue] forKey:@"inputPeriodicity" inFilter:filter];
  [self storeValue:[self radiusValue] forKey:kCIInputRadiusKey inFilter:filter];
  [self storeValue:[self rotationValue] forKey:@"inputRotation" inFilter:filter];
  [self storeValue:[self sharpnessValue] forKey:kCIInputSharpnessKey inFilter:filter];
  [self storeValue:[self strandsValue] forKey:@"inputStrands" inFilter:filter];
  [self storeValue:[self widthValue] forKey:kCIInputWidthKey inFilter:filter];
  [self storeValue:[self zoomValue] forKey:@"inputZoom" inFilter:filter];

  CIImage *result = [filter valueForKey:kCIOutputImageKey];
  CGRect frame = CGRectMake(0, 0, size.width, size.height);
  CGRect sourceFrame;

  if ([self useCroppedImage]) {
    sourceFrame = CGRectMake(0, 0, size.width, size.height);

  } else {
    sourceFrame = CGRectMake(size.width / 2, size.height / 2, size.width, size.height);
  }

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

@end
