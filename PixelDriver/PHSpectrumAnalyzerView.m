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

@implementation PHSpectrumAnalyzerView

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
  [super awakeFromNib];

  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(displayLinkDidFire) name:PHDisplayLinkFiredNotification object:nil];
}

- (void)displayLinkDidFire {
  [self setNeedsDisplay:YES];
}

#pragma mark - Rendering

- (void)drawRect:(NSRect)dirtyRect {
  [super drawRect:dirtyRect];

  CGContextRef cx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
  [[NSColor blackColor] set];
  CGContextFillRect(cx, self.bounds);

  PHFMODRecorder* recorder = PHApp().audioRecorder;

  NSInteger numberOfSpectrumValues = recorder.numberOfSpectrumValues;
  float* spectrum = recorder.spectrum;

  [[NSColor colorWithDeviceRed:1 green:1 blue:1 alpha:1] set];
  CGFloat colWidth = self.bounds.size.width / (CGFloat)numberOfSpectrumValues;
  CGFloat max = 0;
  for (int ix = 0; ix < numberOfSpectrumValues; ++ix) {
    max = MAX(max, spectrum[ix]);
  }
  if (max > 0) {
    for (int ix = 0; ix < numberOfSpectrumValues; ++ix) {
      CGRect rect = CGRectMake(colWidth * ix, 0, colWidth, (spectrum[ix] / .01f) * self.bounds.size.height);
      CGContextFillRect(cx, rect);
    }
  }
}

@end
