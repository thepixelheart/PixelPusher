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

#import "PHSpectrumAnalyzerView.h"

#import "AppDelegate.h"
#import "PHBitmapPipeline.h"
#import "PHDisplayLink.h"
#import "PHFMODRecorder.h"
#import "Utilities.h"

static CVReturn displayLinkCallback(CVDisplayLinkRef displayLink,
                                    const CVTimeStamp* now,
                                    const CVTimeStamp* outputTime,
                                    CVOptionFlags flagsIn,
                                    CVOptionFlags* flagsOut,
                                    void* displayLinkContext) {
  @autoreleasepool {
    [((__bridge PHSpectrumAnalyzerView*)displayLinkContext) setNeedsDisplay:YES];
    return kCVReturnSuccess;
  }
}

@interface PHSpectrumAnalyzerView() <PHBitmapReceiver>
@end

@implementation PHSpectrumAnalyzerView {
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

#pragma mark - Rendering

- (void)drawRect:(NSRect)dirtyRect {
  [super drawRect:dirtyRect];

  [_renderedImage drawAtPoint:CGPointZero fromRect:CGRectZero operation:NSCompositeCopy fraction:1];
}

- (void)queueBitmap {
  [_pipeline queueRenderBlock:^(CGContextRef cx, CGSize size) {
    CGRect bounds = CGRectMake(0, 0, size.width, size.height);
    [[NSColor blackColor] set];
    CGContextFillRect(cx, bounds);

    PHFMODRecorder* recorder = PHApp().audioRecorder;

    NSInteger numberOfSpectrumValues = recorder.numberOfSpectrumValues;
    float* spectrum = recorder.spectrum;

    [[NSColor colorWithDeviceRed:1 green:1 blue:1 alpha:1] set];
    CGFloat colWidth = size.width / (CGFloat)numberOfSpectrumValues;
    CGFloat max = 0;
    for (int ix = 30; ix < numberOfSpectrumValues; ++ix) {
      max = MAX(max, spectrum[ix]);
    }
    if (max > 0) {
      for (int ix = 0; ix < numberOfSpectrumValues; ++ix) {
        CGRect rect = CGRectMake(colWidth * ix, 0, colWidth, (spectrum[ix] / 0.01) * self.bounds.size.height);
        CGContextFillRect(cx, rect);
      }
    }
  } imageSize:self.bounds.size delegate:self];
}

#pragma mark - PHBitmapReceiver

- (void)bitmapDidFinishRendering:(NSImage *)image {
  if (nil != image) {
    _renderedImage = image;
    [self setNeedsDisplay:YES];
  }
}

@end
