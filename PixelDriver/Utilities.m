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

#import "Utilities.h"

void PHAlert(NSString *message) {
  NSAlert *alert = [[NSAlert alloc] init];
  alert.alertStyle = NSCriticalAlertStyle;
  alert.messageText = message;
  [alert runModal];
}

NSString* PHFilenameForResourcePath(NSString* resourcePath) {
  return [@"PixelDriver.app/Contents/Resources/" stringByAppendingPathComponent:resourcePath];
}

CGContextRef PHCreate8BitBitmapContextWithSize(CGSize size) {
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  if (nil == colorSpace) {
    return nil;
  }
  CGContextRef cx =
  CGBitmapContextCreate(NULL,
                        size.width,
                        size.height,
                        8,
                        0,
                        colorSpace,
                        kCGImageAlphaPremultipliedLast);
  CGColorSpaceRelease(colorSpace);
  return cx;
}

NSColor* generateRandomColor() {
    CGFloat hue = ( arc4random_uniform(256) / 256.0f );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random_uniform(256) / 256.0f ) + 0.5f;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random_uniform(256) / 256.0f ) + 0.5f;  //  0.5 to 1.0, away from black
    return [NSColor colorWithDeviceHue:hue saturation:saturation brightness:brightness alpha:0.8];
}

#if 0

// Cuz Anton's running 10.7
// https://gist.github.com/707921
@implementation NSColor (CGColor)
 
- (CGColorRef)CGColor {
    const NSInteger numberOfComponents = [self numberOfComponents];
    CGFloat components[numberOfComponents];
    CGColorSpaceRef colorSpace = [[self colorSpace] CGColorSpace];
 
    [self getComponents:(CGFloat *)&components];
 
    return CGColorCreate(colorSpace, components);
}
 
+ (NSColor *)colorWithCGColor:(CGColorRef)CGColor {
    if (CGColor == NULL) return nil;
    return [NSColor colorWithCIColor:[CIColor colorWithCGColor:CGColor]];
}
 
@end

#endif