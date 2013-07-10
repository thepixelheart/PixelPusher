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

#import "PHScreenCaptureAnimation.h"

static const CGWindowListOption kListOptions = (kCGWindowListOptionOnScreenOnly
                                                | kCGWindowListExcludeDesktopElements
                                                | kCGWindowListOptionIncludingWindow);
static const CGWindowImageOption kImageOptions = (kCGWindowImageBoundsIgnoreFraming
                                                  | kCGWindowImageShouldBeOpaque);

@implementation PHScreenCaptureAnimation {
	NSArray* _windowList;
  CGWindowID _activeWindowNumber;
}

- (id)init {
  if ((self = [super init])) {
    [self updateWindowList];
  }
  return self;
}

- (void)updateWindowList {
  _windowList = CFBridgingRelease(CGWindowListCopyWindowInfo(kListOptions, kCGNullWindowID));

  // Find the active window number to make sure it's still there.
  if (_activeWindowNumber) {
    for (NSDictionary* window in _windowList) {
      CGWindowID windowNumber = [window[(NSString *)kCGWindowNumber] unsignedIntValue];
      if (windowNumber == _activeWindowNumber) {
        break;
      }
    }
  } else if (_windowList.count > 0) {
    _activeWindowNumber = 866;//[[_windowList lastObject][(NSString *)kCGWindowNumber] unsignedIntValue];
  } else {
    _activeWindowNumber = 0;
  }
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);
  if (_activeWindowNumber) {;
    CGImageRef windowImage = CGWindowListCreateImage(CGRectNull, kCGWindowListOptionIncludingWindow, _activeWindowNumber, kImageOptions);
    CGContextScaleCTM(cx, 1, -1);
    CGContextTranslateCTM(cx, 0, -size.height);;    CGContextDrawImage(cx, CGRectMake(0, -3, size.width, size.height + 5), windowImage);
    CGImageRelease(windowImage);
  }
  CGContextRestoreGState(cx);
}

- (NSString *)tooltipName {
  return @"Screen Capture";
}

@end
