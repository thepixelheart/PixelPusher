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
#import "PHCompositeEditorView.h"
#import "PHActionsView.h"

static const CGFloat kHeaderBarHeight = 30;
static const CGFloat kVisualizerMaxHeight = 300;
static const CGFloat kCompositeEditorMaxHeight = 400;
static const CGFloat kWallVisualizerMaxHeight = 130;
static const CGFloat kPlaybackControlsHeight = 40;

@interface PHDualVizualizersView() <PHPlaybackControlsViewDelegate>
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
  PHCompositeEditorView* _compositeEditorView;

  PHViewMode _viewMode;
  BOOL _fullscreened;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObject:self];
}

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    _viewMode = PHSys().viewMode;
    _fullscreened = PHSys().fullscreenMode;

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
    [nc addObserver:self selector:@selector(didChangeViewStateNotification:) name:PHSystemViewStateChangedNotification object:nil];
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
  CGFloat maxVisualizerHeight = MIN(kVisualizerMaxHeight, self.bounds.size.height / 3);
  if (visualizerHeight > maxVisualizerHeight) {
    visualizerHeight = maxVisualizerHeight;
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
  
  if (_viewMode != PHViewModeUmanoMode) {
    _playbackControlsView.frame = CGRectMake(0, topEdge, self.bounds.size.width, kPlaybackControlsHeight);
    [_playbackControlsView layout];
    
    CGRect contentFrame = CGRectMake(0, 0, self.bounds.size.width, topEdge);
    if (_viewMode == PHViewModePrefs) {
      _prefsView.frame = contentFrame;
      [_prefsView layout];
      
    } else if (_viewMode == PHViewModeCompositeEditor) {
      CGRect compositeEditorFrame = contentFrame;
      compositeEditorFrame.size.height = MIN(kCompositeEditorMaxHeight, compositeEditorFrame.size.height / 3);
      compositeEditorFrame.origin.y = topEdge - compositeEditorFrame.size.height;
      
      _compositeEditorView.frame = compositeEditorFrame;
      [_compositeEditorView layout];
      
      CGRect libraryFrame = compositeEditorFrame;
      libraryFrame.origin.y = 0;
      libraryFrame.size.height = contentFrame.size.height - compositeEditorFrame.size.height;
      _libraryView.frame = libraryFrame;
      [_libraryView layout];
      
    } else {
      _libraryView.frame = contentFrame;
      [_libraryView layout];
    }
  } else {
    
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

- (void)didChangeViewStateNotification:(NSNotification *)notification {
  PHViewMode newViewMode = PHSys().viewMode;
  if (newViewMode != _viewMode) {
    _viewMode = newViewMode;

    [_prefsView removeFromSuperview];
    _prefsView = nil;
    [_compositeEditorView removeFromSuperview];
    _compositeEditorView = nil;

    BOOL hideLibrary = NO;
    BOOL hidePlaybackControls = NO;

    if (_viewMode == PHViewModePrefs) {
      _prefsView = [[PHPrefsView alloc] init];
      [self addSubview:_prefsView];
      hideLibrary = YES;
    } else if (_viewMode == PHViewModeCompositeEditor) {
      _compositeEditorView = [[PHCompositeEditorView alloc] init];
      [self addSubview:_compositeEditorView];
    } else if (_viewMode == PHViewModeUmanoMode) {
      hideLibrary = YES;
      hidePlaybackControls = YES;
    }

    [_libraryView setHidden:hideLibrary];
    [_playbackControlsView setHidden:hidePlaybackControls];
  }
  BOOL newFullscreenMode = PHSys().fullscreenMode;
  if (_fullscreened != newFullscreenMode) {
    _fullscreened = newFullscreenMode;
    if (newFullscreenMode) {
      NSDictionary* options = [NSDictionary
                               dictionaryWithObjectsAndKeys:
                               [NSNumber numberWithBool:YES],
                               NSFullScreenModeAllScreens, nil];
      [_wallVisualizationView enterFullScreenMode:[NSScreen mainScreen]
                         withOptions:options];
      [_wallVisualizationView setFrame:[NSScreen mainScreen].frame];
    } else {
      NSDictionary* options = [NSDictionary
                               dictionaryWithObjectsAndKeys:
                               [NSNumber numberWithBool:NO],
                               NSFullScreenModeAllScreens, nil];
      [_wallVisualizationView exitFullScreenModeWithOptions:options];
    }
  }
}

@end
