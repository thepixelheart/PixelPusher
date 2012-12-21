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
  CGImageRef _renderedImage;
}

- (void)dealloc {
  if (nil != _renderedImage) {
    CGImageRelease(_renderedImage);
  }
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
  [super awakeFromNib];

  _pipeline = [[PHBitmapPipeline alloc] init];

  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(displayLinkDidFire:) name:PHDisplayLinkFiredNotification object:nil];
}

- (void)displayLinkDidFire:(NSNotification *)notification {
  float* spectrum = [notification.userInfo[PHDisplayLinkFiredSpectrumKey] pointerValue];
  NSInteger numberOfSpectrumValues = [notification.userInfo[PHDisplayLinkFiredNumberOfSpectrumValuesKey] longValue];
  [self queueBitmapWithSpectrum:spectrum numberOfSpectrumValues:numberOfSpectrumValues];
}

- (void)drawRect:(NSRect)dirtyRect {
  [super drawRect:dirtyRect];

  CGContextRef cx = [[NSGraphicsContext currentContext] graphicsPort];
  CGContextSetInterpolationQuality(cx, kCGInterpolationNone);

  if (nil != _renderedImage) {
    CGContextDrawImage(cx, CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height), _renderedImage);
    CGImageRelease(_renderedImage);
    _renderedImage = nil;
  }
}

- (void)queueBitmapWithSpectrum:(float *)spectrum numberOfSpectrumValues:(NSInteger)numberOfSpectrumValues {
  [_pipeline queueRenderBlock:^(CGContextRef cx, CGSize size) {
    [self renderBitmapInContext:cx size:size spectrum:spectrum numberOfSpectrumValues:numberOfSpectrumValues];
  } imageSize:self.bounds.size delegate:self];
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

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size spectrum:(float *)spectrum numberOfSpectrumValues:(NSInteger)numberOfSpectrumValues {
  // No-op
}

@end
