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

#import "PHContainerView.h"

#import "Utilities.h"

static const NSEdgeInsets kContentInset = {2, 2, 2, 2};

@implementation PHContainerView

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    self.wantsLayer = YES;

    _contentView = [[NSView alloc] initWithFrame:UIEdgeInsetRect(self.bounds, kContentInset)];
    _contentView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self addSubview:_contentView];
  }
  return self;
}

- (NSDictionary *)textAttributes {
  return @{
    NSForegroundColorAttributeName:[NSColor colorWithDeviceWhite:0.5 alpha:1],
    NSFontAttributeName:[NSFont boldSystemFontOfSize:12]
  };
}

- (void)drawRect:(NSRect)dirtyRect {
  CGRect contentFrame = UIEdgeInsetRect(self.bounds, kContentInset);
  CGFloat frameHeight = self.bounds.size.height;

  if (_title.length > 0) {
    CGSize size = [_title sizeWithAttributes:[self textAttributes]];

    [[NSColor whiteColor] setFill];
    [_title drawInRect:CGRectMake(6, self.bounds.size.height - size.height, size.width, size.height) withAttributes:[self textAttributes]];

    contentFrame.size.height -= size.height;
    frameHeight -= size.height;
  }

  NSColor* startingColor = [NSColor colorWithDeviceWhite:0.2 alpha:1];
  NSColor* endingColor = [NSColor colorWithDeviceWhite:0.25 alpha:1];
  NSGradient *grad = [[NSGradient alloc] initWithStartingColor:startingColor endingColor:endingColor];
  [grad drawInRect:contentFrame angle:90];

  NSColor* lightBorderColor = [NSColor colorWithDeviceWhite:0.25 alpha:1];
  NSColor* darkBorderColor = [NSColor colorWithDeviceWhite:0.2 alpha:1];
  [lightBorderColor setFill];
  [[NSBezierPath bezierPathWithRect:
    CGRectMake(1, 1,
               self.bounds.size.width - 2, 1)] fill];
  [darkBorderColor setFill];
  [[NSBezierPath bezierPathWithRect:
    CGRectMake(1, frameHeight - 2,self.bounds.size.width - 2, 1)] fill];

  grad = [[NSGradient alloc] initWithStartingColor:lightBorderColor endingColor:endingColor];
  [grad drawInRect:CGRectMake(1, 1, 1, frameHeight - 3) angle:90];
  [grad drawInRect:CGRectMake(self.bounds.size.width - 2, 1, 1, frameHeight - 3) angle:90];
}

- (void)layout {
  [super layout];

  CGRect contentFrame = UIEdgeInsetRect(self.bounds, kContentInset);
  if (_title.length > 0) {
    CGSize size = [_title sizeWithAttributes:[self textAttributes]];
    size.height += 4;
    contentFrame.size.height -= size.height;
  }
  _contentView.frame = contentFrame;
}

@end
