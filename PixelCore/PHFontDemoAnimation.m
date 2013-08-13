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

#import "PHFontDemoAnimation.h"

#import "PHFont.h"

@implementation PHFontDemoAnimation

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  NSString* string = @"THis is a string that will expand everything";
  CGSize fontSize = [PHFont sizeOfString:string withConstraints:size];
  CGContextSetFillColorWithColor(cx, [NSColor redColor].CGColor);
  CGContextFillRect(cx, CGRectMake(0, 0, fontSize.width, fontSize.height));
  [PHFont renderString:string inRect:CGRectMake(0, 0, size.width, size.height) inContext:cx];
}

@end
