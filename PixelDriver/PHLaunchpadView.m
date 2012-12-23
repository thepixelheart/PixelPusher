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

#import "PHLaunchpadView.h"

@implementation PHLaunchpadView

- (void)awakeFromNib {
  [super awakeFromNib];

  for (NSView* view in self.subviews) {
    if ([view isKindOfClass:[NSButton class]]) {
      NSButton* button = (NSButton *)view;
      button.target = self;
      button.action = @selector(didTapButton:);
    }
  }
}

- (void)drawRect:(NSRect)dirtyRect {
  [NSGraphicsContext saveGraphicsState];

  [[NSColor colorWithDeviceRed:0.1 green:0.1 blue:0.1 alpha:1] set];
  CGContextRef cx = [[NSGraphicsContext currentContext] graphicsPort];

  CGFloat radius = 20;
  CGRect rect = self.bounds;
  // http://stackoverflow.com/questions/1031930/how-is-a-rounded-rect-view-with-transparency-done-on-iphone/1031936#1031936
  CGContextMoveToPoint(cx, rect.origin.x, rect.origin.y + radius);
  CGContextAddLineToPoint(cx, rect.origin.x, rect.origin.y + rect.size.height - radius);
  CGContextAddArc(cx, rect.origin.x + radius, rect.origin.y + rect.size.height - radius,
                  radius, M_PI, M_PI / 2, 1);
  CGContextAddLineToPoint(cx, rect.origin.x + rect.size.width - radius,
                          rect.origin.y + rect.size.height);
  CGContextAddArc(cx, rect.origin.x + rect.size.width - radius,
                  rect.origin.y + rect.size.height - radius, radius, M_PI / 2, 0.0f, 1);
  CGContextAddLineToPoint(cx, rect.origin.x + rect.size.width, rect.origin.y + radius);
  CGContextAddArc(cx, rect.origin.x + rect.size.width - radius, rect.origin.y + radius,
                  radius, 0.0f, -M_PI / 2, 1);
  CGContextAddLineToPoint(cx, rect.origin.x + radius, rect.origin.y);
  CGContextAddArc(cx, rect.origin.x + radius, rect.origin.y + radius, radius,
                  -M_PI / 2, M_PI, 1);

  CGContextFillPath(cx);

  [NSGraphicsContext restoreGraphicsState];

  [super drawRect:dirtyRect];
}

- (IBAction)didTapButton:(id)sender {
  
}

@end
