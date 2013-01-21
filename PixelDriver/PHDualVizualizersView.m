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
#import "PHPrefsView.h"
#import "PHActionsView.h"

NSString* const PHChangeCurrentViewNotification = @"PHChangeCurrentViewNotification";
NSString* const PHChangeCurrentViewKey = @"PHChangeCurrentViewKey";

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
  PHActionsView* _actionsView;

  PHPlaybackControlsView* _playbackControlsView;

  PHLibraryView* _libraryView;
  PHPrefsView* _prefsView;

  PHViewMode _viewMode;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObject:self];
}

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    _viewMode = PHViewModeLibrary;

    self.wantsLayer = YES;
    [self.layer setBackgroundColor:PHBackgroundColor().CGColor];

    CGRect bounds = self.bounds;

    // Header bar
    CGRect frame = CGRectMake(0, bounds.size.height - kHeaderBarHeight,
                              bounds.size.width, kHeaderBarHeight);
    _headerBarView = [[PHHeaderView alloc] initWithFrame:frame];
    _headerBarView.autoresizingMask = (NSViewWidthSizable | NSViewMinYMargin);
    _headerBarView.delegate = self;
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

    // Actions
    _actionsView = [[PHActionsView alloc] init];
    [self addSubview:_actionsView];

    // Playback controls
    _playbackControlsView = [[PHPlaybackControlsView alloc] init];
    _playbackControlsView.delegate = self;
    [self addSubview:_playbackControlsView];

    _libraryView = [[PHLibraryView alloc] init];
    [self addSubview:_libraryView];

    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(didChangeViewMode:) name:PHChangeCurrentViewNotification object:nil];
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

  _actionsView.frame = CGRectMake(midX - wallWidth / 2, topEdge + wallHeight, wallWidth, CGRectGetMinY(_headerBarView.frame) - (topEdge + wallHeight));
  [_actionsView layout];

  topEdge -= kPlaybackControlsHeight;

  _playbackControlsView.frame = CGRectMake(0, topEdge, self.bounds.size.width, kPlaybackControlsHeight);
  [_playbackControlsView layout];

  CGRect contentFrame = CGRectMake(0, 0, self.bounds.size.width, topEdge);
  if (_viewMode == PHViewModePrefs) {
    _prefsView.frame = contentFrame;
    [_prefsView layout];

  } else if (_viewMode == PHViewModeLibrary) {
    _libraryView.frame = contentFrame;
    [_libraryView layout];
  }
}

#pragma mark - PHHeaderViewDelegate

- (void)didTapPrefsButton {
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  if (_viewMode != PHViewModePrefs) {
    [nc postNotificationName:PHChangeCurrentViewNotification object:nil userInfo:
     @{PHChangeCurrentViewKey: [NSNumber numberWithInt:PHViewModePrefs]}];
  } else {
    [nc postNotificationName:PHChangeCurrentViewNotification object:nil userInfo:
     @{PHChangeCurrentViewKey: [NSNumber numberWithInt:PHViewModeLibrary]}];
  }
}

#pragma mark - PHPlaybackControlsViewDelegate

- (void)didTapLoadLeftButton {
  [PHSys() didPressButton:PHSystemButtonLoadLeft];
}

- (void)didTapLoadRightButton {
  [PHSys() didPressButton:PHSystemButtonLoadRight];
}

#pragma mark - View Mode Notifications

- (void)didChangeViewMode:(NSNotification *)notification {
  _viewMode = [notification.userInfo[PHChangeCurrentViewKey] intValue];
  if (_viewMode == PHViewModePrefs) {
    if (nil == _prefsView) {
      _prefsView = [[PHPrefsView alloc] init];
      [self addSubview:_prefsView];
    }
    [_libraryView setHidden:YES];

  } else if (_viewMode == PHViewModeLibrary) {
    [_prefsView removeFromSuperview];
    _prefsView = nil;
    [_libraryView setHidden:NO];
  }

  [self setNeedsLayout:YES];
}

@end
