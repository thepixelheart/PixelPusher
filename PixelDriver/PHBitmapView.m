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

#import "PHBitmapView.h"

#import "PHBitmapPipeline.h"
#import "PHDisplayLink.h"
#import "PHAnimationDriver.h"

@interface PHBitmapView() <PHBitmapReceiver>
@end

@implementation PHBitmapView {
  PHBitmapPipeline* _pipeline;
  CGImageRef _renderedImage;
}

- (void)dealloc {
  if (nil != _renderedImage) {
    CGImageRelease(_renderedImage);
  }
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)commonInit {
  _pipeline = [[PHBitmapPipeline alloc] init];

  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(displayLinkDidFire:) name:PHDisplayLinkFiredNotification object:nil];
}

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    [self commonInit];
  }
  return self;
}

- (void)awakeFromNib {
  [super awakeFromNib];

  [self commonInit];
}

- (void)displayLinkDidFire:(NSNotification *)notification {
  PHAnimationDriver* driver = notification.userInfo[PHDisplayLinkFiredDriverKey];
  [self queueBitmapWithDriver:driver];
}

- (void)drawRect:(NSRect)dirtyRect {
  [super drawRect:dirtyRect];

  CGContextRef cx = [[NSGraphicsContext currentContext] graphicsPort];
  CGContextSetInterpolationQuality(cx, kCGInterpolationNone);

  if (nil != _renderedImage) {
    CGContextDrawImage(cx, CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height), _renderedImage);
  }
}

- (void)queueBitmapWithDriver:(PHAnimationDriver *)driver {
  [_pipeline queueRenderBlock:^(CGContextRef cx, CGSize size) {
    [self renderBitmapInContext:cx size:size driver:driver];
  } imageSize:self.bounds.size delegate:self priority:self.threadPriority];
}

#pragma mark - PHBitmapReceiver

- (void)bitmapDidFinishRendering:(CGImageRef)imageRef {
  if (nil != imageRef) {
    if (nil != _renderedImage) {
      CGImageRelease(_renderedImage);
    }
    CGImageRetain(imageRef);
    _renderedImage = imageRef;
    [self setNeedsDisplay:YES];
  }
}

#pragma mark - Subclassing

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size driver:(PHAnimationDriver *)driver {
  // No-op
}

- (double)threadPriority {
  return 0.5;
}

@end
