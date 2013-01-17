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

#import <Foundation/Foundation.h>

NSColor* PHBackgroundColor();

void PHAlert(NSString* message);
NSString* PHFilenameForResourcePath(NSString* resourcePath);

CGContextRef PHCreate8BitBitmapContextWithSize(CGSize size);

NSTimeInterval PHEaseInEaseOut(NSTimeInterval t);
NSTimeInterval PHEaseIn(NSTimeInterval t);
NSTimeInterval PHEaseOut(NSTimeInterval t);

CGRect UIEdgeInsetRect(CGRect rect, NSEdgeInsets insets);

NSColor* generateRandomColor();

#if __MAC_OS_X_VERSION_MAX_ALLOWED <= __MAC_10_7

// Cuz Anton's running 10.7
// https://gist.github.com/707921
@interface NSColor (CGColor)

//
// The Quartz color reference that corresponds to the receiver's color.
//
@property (nonatomic, readonly) CGColorRef CGColor;

//
// Converts a Quartz color reference to its NSColor equivalent.
//
+ (NSColor *)colorWithCGColor:(CGColorRef)color;

@end

#endif
