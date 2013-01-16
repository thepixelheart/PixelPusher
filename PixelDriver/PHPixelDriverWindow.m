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

#import "PHPixelDriverWindow.h"

#import "PHHeaderView.h"

static const CGSize kMinimumWindowSize = {400, 400};
static const CGFloat kHeaderBarHeight = 30;
static const CGFloat kVisualizerHeight = 400;

NSColor* PHBackgroundColor() {
  static NSColor* color = nil;
  if (nil == color) {
    color = [NSColor colorWithDeviceWhite:0.1 alpha:1];
  }
  return color;
}

static NSString* const kPixelDriverWindowFrameName = @"kPixelDriverWindowFrameName";

@implementation PHPixelDriverWindow {
  PHHeaderView* _headerBarView;
  PHContainerView* _leftVisualizationView;
  PHContainerView* _rightVisualizationView;
}

- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSUInteger)aStyle
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)flag {
  if ((self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag])) {
    [self setMinSize:kMinimumWindowSize];
    [self setFrameAutosaveName:kPixelDriverWindowFrameName];

    [self.contentView setWantsLayer:YES];
    [[self.contentView layer] setBackgroundColor:PHBackgroundColor().CGColor];

    CGRect bounds = [self.contentView bounds];

    // Header bar
    CGRect frame = CGRectMake(0, bounds.size.height - kHeaderBarHeight,
                              bounds.size.width, kHeaderBarHeight);
    _headerBarView = [[PHHeaderView alloc] initWithFrame:frame];
    _headerBarView.autoresizingMask = (NSViewWidthSizable | NSViewMinYMargin);
    [self.contentView addSubview:_headerBarView];

    // Left visualization
    frame = CGRectMake(0, bounds.size.height - kHeaderBarHeight - kVisualizerHeight,
                       bounds.size.width / 2, kVisualizerHeight);
    _leftVisualizationView = [[PHContainerView alloc] initWithFrame:frame];
    _leftVisualizationView.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable
                                               | NSViewMaxXMargin | NSViewMinYMargin);
    [self.contentView addSubview:_leftVisualizationView];

    frame = CGRectMake(bounds.size.width / 2, bounds.size.height - kHeaderBarHeight - kVisualizerHeight,
                       bounds.size.width / 2, kVisualizerHeight);
    _rightVisualizationView = [[PHContainerView alloc] initWithFrame:frame];
    _rightVisualizationView.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable
                                                | NSViewMinXMargin | NSViewMinYMargin);
    [self.contentView addSubview:_rightVisualizationView];
  }
  return self;
}

@end
