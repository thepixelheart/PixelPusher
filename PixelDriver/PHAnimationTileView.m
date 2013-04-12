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

#import "PHAnimationTileView.h"

#import "PHAnimation.h"

@implementation PHAnimationTileView {
  CGImageRef _previewImageRef;
}

- (void)dealloc {
  if (nil != _previewImageRef) {
    CGImageRelease(_previewImageRef);
    _previewImageRef = nil;
  }
}

- (id)initWithFrame:(NSRect)frameRect {
  CGFloat aspectRatio = (CGFloat)kWallWidth / (CGFloat)kWallHeight;
  self = [super initWithFrame:(NSRect){frameRect.origin, CGSizeMake(150 * aspectRatio, 150)}];
  if (self) {
  }
  return self;
}

- (void)drawRect:(NSRect)dirtyRect {
  if (_selected) {
    [[NSColor colorWithDeviceWhite:1 alpha:0.2] set];
    NSRectFill([self bounds]);
  }

  if (nil == _previewImageRef) {
    CGSize wallSize = CGSizeMake(kWallWidth, kWallHeight);
    CGContextRef contextRef = PHCreate8BitBitmapContextWithSize(wallSize);
    [_animation renderPreviewInContext:contextRef size:wallSize];

    _previewImageRef = CGBitmapContextCreateImage(contextRef);
    CGContextRelease(contextRef);
  }

  CGContextRef cx = [[NSGraphicsContext currentContext] graphicsPort];
  CGContextSaveGState(cx);
  CGContextScaleCTM(cx, 1, -1);
  CGContextTranslateCTM(cx, 0, -self.bounds.size.height);

  if (_selected) {
    CGContextSetAlpha(cx, 1);
  } else {
    CGContextSetAlpha(cx, 0.5);
  }

  CGContextSetInterpolationQuality(cx, kCGInterpolationNone);
  CGRect insetBounds = CGRectInset(self.bounds, 5, 5);
  CGFloat aspectRatio = (CGFloat)kWallHeight / (CGFloat)kWallWidth;
  CGFloat width = insetBounds.size.width;
  CGFloat height = width * aspectRatio;
  if (height > insetBounds.size.height) {
    height = insetBounds.size.height;
    width = height / aspectRatio;
  }
  CGContextDrawImage(cx, CGRectMake(insetBounds.origin.x + floor((insetBounds.size.width - width) / 2),
                                    insetBounds.origin.y + floor((insetBounds.size.height - height) / 2),
                                    width, height), _previewImageRef);
  CGContextRestoreGState(cx);

  if (_animation.tooltipName.length > 0) {
    NSDictionary* attributes = @{
      NSForegroundColorAttributeName:[NSColor colorWithDeviceWhite:_selected ? 1.0 : 0.6 alpha:1],
      NSFontAttributeName:[NSFont boldSystemFontOfSize:11]
    };
    NSMutableAttributedString* string = [[NSMutableAttributedString alloc] initWithString:_animation.tooltipName attributes:attributes];
    [string setAlignment:NSCenterTextAlignment range:NSMakeRange(0, string.length)];
    CGRect textFrame = CGRectInset(self.bounds, 5, 5);
    CGSize size = [string.string sizeWithAttributes:attributes];
    textFrame.size.height = size.height;

    CGContextSetRGBFillColor(cx, 0, 0, 0, 0.6);
    CGContextFillRect(cx, CGRectMake(0, 0, self.bounds.size.width, size.height + 10));

    [string drawInRect:textFrame];
  }
}

- (void)setAnimation:(PHAnimation *)animation {
  if (_animation != animation) {
    _animation = [animation copy];

    if (nil != _previewImageRef) {
      CGImageRelease(_previewImageRef);
      _previewImageRef = nil;
    }
  }
}

@end
