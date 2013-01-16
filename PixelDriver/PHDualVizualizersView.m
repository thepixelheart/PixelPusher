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

#import "PHDualVizualizersView.h"

#import "PHHeaderView.h"
#import "PHDriver.h"
#import "PHWallView.h"
#import "PHPlaybackControlsView.h"

static const CGFloat kHeaderBarHeight = 30;
static const CGFloat kVisualizerMaxHeight = 300;
static const CGFloat kPlaybackControlsHeight = 60;

NSColor* PHBackgroundColor() {
  static NSColor* color = nil;
  if (nil == color) {
    color = [NSColor colorWithDeviceWhite:0.1 alpha:1];
  }
  return color;
}

@implementation PHDualVizualizersView {
  PHHeaderView* _headerBarView;
  PHContainerView* _leftVisualizationView;
  PHContainerView* _rightVisualizationView;

  PHPlaybackControlsView* _playbackControlsView;
}

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    self.wantsLayer = YES;
    [self.layer setBackgroundColor:PHBackgroundColor().CGColor];

    CGRect bounds = self.bounds;

    // Header bar
    CGRect frame = CGRectMake(0, bounds.size.height - kHeaderBarHeight,
                              bounds.size.width, kHeaderBarHeight);
    _headerBarView = [[PHHeaderView alloc] initWithFrame:frame];
    _headerBarView.autoresizingMask = (NSViewWidthSizable | NSViewMinYMargin);
    [self addSubview:_headerBarView];

    // Left visualization
    _leftVisualizationView = [[PHContainerView alloc] initWithFrame:NSZeroRect];
    [self addSubview:_leftVisualizationView];

    PHWallView* wallView = [[PHWallView alloc] initWithFrame:_leftVisualizationView.contentView.bounds];
    wallView.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
    wallView.primary = YES;
    [_leftVisualizationView.contentView addSubview:wallView];

    // Right vizualization
    _rightVisualizationView = [[PHContainerView alloc] initWithFrame:NSZeroRect];
    [self addSubview:_rightVisualizationView];

    wallView = [[PHWallView alloc] initWithFrame:_leftVisualizationView.contentView.bounds];
    wallView.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
    wallView.primary = NO;
    [_rightVisualizationView.contentView addSubview:wallView];

    _playbackControlsView = [[PHPlaybackControlsView alloc] init];
    [self addSubview:_playbackControlsView];
  }
  return self;
}

- (void)layout {
  [super layout];

  CGFloat visualizerAspectRatio = (CGFloat)kWallHeight / (CGFloat)kWallWidth;
  CGFloat midX = self.bounds.size.width / 2;
  CGFloat visualizerMaxWidth = (self.bounds.size.width - PHPlaybackControlsWidth) / 2;
  CGFloat visualizerWidth = visualizerMaxWidth;

  CGFloat visualizerHeight = visualizerMaxWidth * visualizerAspectRatio;
  if (visualizerHeight > kVisualizerMaxHeight) {
    visualizerHeight = kVisualizerMaxHeight;
    visualizerWidth = visualizerHeight / visualizerAspectRatio;
  }

  CGFloat topEdge = self.bounds.size.height - kHeaderBarHeight - visualizerHeight;
  _leftVisualizationView.frame = CGRectMake(floorf((visualizerMaxWidth - visualizerWidth) / 2), topEdge,
                                            visualizerWidth, visualizerHeight);
  _rightVisualizationView.frame = CGRectMake(midX + PHPlaybackControlsWidth / 2 + floorf((visualizerMaxWidth - visualizerWidth) / 2), topEdge,
                                             visualizerWidth, visualizerHeight);

  topEdge -= kPlaybackControlsHeight;

  _playbackControlsView.frame = CGRectMake(0, topEdge, self.bounds.size.width, kPlaybackControlsHeight);
  [_playbackControlsView layout];
}

@end
