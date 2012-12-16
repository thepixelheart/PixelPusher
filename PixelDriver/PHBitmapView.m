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

@interface PHBitmapView() <PHBitmapReceiver>
@end

@implementation PHBitmapView {
  PHBitmapPipeline* _pipeline;
  NSImage* _renderedImage;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
  [super awakeFromNib];

  _pipeline = [[PHBitmapPipeline alloc] init];

  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(displayLinkDidFire) name:PHDisplayLinkFiredNotification object:nil];
}

- (void)displayLinkDidFire {
  [self queueBitmap];
}

- (void)drawRect:(NSRect)dirtyRect {
  [super drawRect:dirtyRect];

  [_renderedImage drawAtPoint:CGPointZero fromRect:CGRectZero operation:NSCompositeCopy fraction:1];
}

- (void)queueBitmap {
  [_pipeline queueRenderBlock:^(CGContextRef cx, CGSize size) {
    [self renderBitmapInContext:cx size:size];
  } imageSize:self.bounds.size delegate:self];
}

#pragma mark - PHBitmapReceiver

- (void)bitmapDidFinishRendering:(NSImage *)image {
  if (nil != image) {
    _renderedImage = image;
    [self setNeedsDisplay:YES];
  }
}

#pragma mark - Subclassing

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  // No-op
}

@end
