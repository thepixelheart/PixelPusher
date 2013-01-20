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

#import "AppDelegate.h"
#import "PHAnimation.h"
#import "PHHeaderView.h"
#import "PHDriver.h"
#import "PHWallView.h"
#import "PHPlaybackControlsView.h"
#import "PHTransition.h"
#import "PHSystem.h"
#import "PHLibraryView.h"

static const CGFloat kHeaderBarHeight = 30;
static const CGFloat kVisualizerMaxHeight = 300;
static const CGFloat kWallVisualizerMaxHeight = 130;
static const CGFloat kPlaybackControlsHeight = 60;

@interface PHDualVizualizersView() <PHPlaybackControlsViewDelegate, PHHeaderViewDelegate>
@end

@implementation PHDualVizualizersView {
  PHHeaderView* _headerBarView;
  PHContainerView* _leftVisualizationView;
  PHContainerView* _rightVisualizationView;
  PHContainerView* _wallVisualizationView;

  PHPlaybackControlsView* _playbackControlsView;

  PHLibraryView* _libraryView;
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
    wallView.systemContext = PHSystemContextLeft;
    [_leftVisualizationView.contentView addSubview:wallView];

    // Right vizualization
    _rightVisualizationView = [[PHContainerView alloc] initWithFrame:NSZeroRect];
    [self addSubview:_rightVisualizationView];

    wallView = [[PHWallView alloc] initWithFrame:_leftVisualizationView.contentView.bounds];
    wallView.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
    wallView.systemContext = PHSystemContextRight;
    [_rightVisualizationView.contentView addSubview:wallView];

    // Wall vizualization
    _wallVisualizationView = [[PHContainerView alloc] initWithFrame:NSZeroRect];
    [self addSubview:_wallVisualizationView];

    wallView = [[PHWallView alloc] initWithFrame:_wallVisualizationView.contentView.bounds];
    wallView.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
    wallView.systemContext = PHSystemContextWall;
    [_wallVisualizationView.contentView addSubview:wallView];

    // Playback controls
    _playbackControlsView = [[PHPlaybackControlsView alloc] init];
    _playbackControlsView.delegate = self;
    [self addSubview:_playbackControlsView];

    _libraryView = [[PHLibraryView alloc] init];
    [self addSubview:_libraryView];
  }
  return self;
}

- (void)layout {
  [super layout];

  [_headerBarView layout];

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

  CGFloat wallWidth = CGRectGetMinX(_rightVisualizationView.frame) - CGRectGetMaxX(_leftVisualizationView.frame);
  CGFloat wallHeight = wallWidth * visualizerAspectRatio;
  if (wallHeight >= kWallVisualizerMaxHeight) {
    wallHeight = kWallVisualizerMaxHeight;
    wallWidth = wallHeight / visualizerAspectRatio;
  }
  _wallVisualizationView.frame = CGRectMake(midX - wallWidth / 2, topEdge,
                                            wallWidth, wallHeight);

  topEdge -= kPlaybackControlsHeight;

  _playbackControlsView.frame = CGRectMake(0, topEdge, self.bounds.size.width, kPlaybackControlsHeight);
  [_playbackControlsView layout];

  _libraryView.frame = CGRectMake(0, 0, self.bounds.size.width, topEdge);
  [_libraryView layout];
}

#pragma mark - PHHeaderViewDelegate

- (void)didTapPrefsButton {
  
}

@end
