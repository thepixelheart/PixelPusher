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

#import "PHLibraryView.h"

#import "AppDelegate.h"
#import "PHSystem.h"
#import "PHAnimation.h"
#import "PHTransition.h"
#import "PHListView.h"
#import "PHAnimationsView.h"
#import "PHWallView.h"
#import "PHDisplayLink.h"

static const CGFloat kPreviewPaneWidth = 300;
static const CGFloat kExplorerWidth = 200;

@interface PHLibraryView() <PHListViewDelegate, PHListViewDataSource>
@end

@implementation PHLibraryView {
  PHListView* _categoriesView;
  PHListView* _transitionsView;
  PHAnimationsView* _animationsView;
  PHContainerView* _previewVisualizationView;
  NSTextField* _tapBpmLabel;
  NSTextField* _lastScriptErrorLabel;

  NSArray* _categories;
  NSArray* _transitions;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    // Preview vizualization
    _previewVisualizationView = [[PHContainerView alloc] initWithFrame:NSZeroRect];
    [self addSubview:_previewVisualizationView];

    _tapBpmLabel = [[NSTextField alloc] init];
    _tapBpmLabel.backgroundColor = [NSColor clearColor];
    [_tapBpmLabel setBordered:NO];
    [_tapBpmLabel setBezeled:NO];
    [_tapBpmLabel setEditable:NO];
    _tapBpmLabel.textColor = [NSColor whiteColor];

    _lastScriptErrorLabel = [[NSTextField alloc] init];
    _lastScriptErrorLabel.backgroundColor = [NSColor clearColor];
    [_lastScriptErrorLabel setBordered:NO];
    [_lastScriptErrorLabel setBezeled:NO];
    [_lastScriptErrorLabel setEditable:NO];
    _lastScriptErrorLabel.textColor = [NSColor whiteColor];

    [self addSubview:_tapBpmLabel];
    [self addSubview:_lastScriptErrorLabel];

    PHWallView* wallView = [[PHWallView alloc] initWithFrame:_previewVisualizationView.contentView.bounds];
    wallView.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
    wallView.systemContext = PHSystemContextPreview;
    [_previewVisualizationView.contentView addSubview:wallView];

    _categoriesView = [[PHListView alloc] init];
    _categoriesView.tag = PHSystemAnimationGroups;
    _categoriesView.title = @"Categories";
    _categoriesView.dataSource = self;
    _categoriesView.delegate = self;
    [self addSubview:_categoriesView];

    _transitionsView = [[PHListView alloc] init];
    _transitionsView.title = @"Transitions";
    _transitionsView.tag = PHSystemTransitions;
    _transitionsView.dataSource = self;
    _transitionsView.delegate = self;
    [self addSubview:_transitionsView];

    // Animations
    _animationsView = [[PHAnimationsView alloc] init];
    [self addSubview:_animationsView];

    _categories = [PHSys() allCategories];
    _transitions = [PHTransition allTransitions];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(activeCategoryDidChangeNotification:) name:PHSystemActiveCategoryDidChangeNotification object:nil];
    [nc addObserver:self selector:@selector(displayLinkDidFire:) name:PHDisplayLinkFiredNotification object:nil];
  }
  return self;
}

- (void)layout {
  [super layout];

  CGFloat topEdge = self.bounds.size.height;
  _animationsView.frame = CGRectMake(kExplorerWidth, 0, self.bounds.size.width - kPreviewPaneWidth - kExplorerWidth, topEdge);
  [_animationsView layout];

  _categoriesView.frame = CGRectMake(0, topEdge / 2, kExplorerWidth, topEdge / 2);
  [_categoriesView layout];

  _transitionsView.frame = CGRectMake(0, 0, kExplorerWidth, topEdge / 2);
  [_transitionsView layout];

  CGFloat visualizerAspectRatio = (CGFloat)kWallHeight / (CGFloat)kWallWidth;
  CGFloat previewHeight = kPreviewPaneWidth * visualizerAspectRatio;
  _previewVisualizationView.frame = CGRectMake(CGRectGetMaxX(_animationsView.frame),
                                               floor((topEdge - previewHeight) / 2),
                                               kPreviewPaneWidth, previewHeight);

  [self updateBpm];
}

- (void)updateBpm {
  NSString* lastScriptError = PHSys().lastScriptError;
  if (lastScriptError.length > 0) {
    if (![_lastScriptErrorLabel.stringValue isEqualToString:lastScriptError]) {
      _lastScriptErrorLabel.layer.hidden = NO;
      _lastScriptErrorLabel.stringValue = lastScriptError;
      _lastScriptErrorLabel.frame = CGRectMake(_previewVisualizationView.frame.origin.x, CGRectGetMaxY(_previewVisualizationView.frame), _previewVisualizationView.frame.size.width, self.bounds.size.height - CGRectGetMaxY(_previewVisualizationView.frame));
    }

  } else {
    _lastScriptErrorLabel.layer.hidden = YES;
  }

  CGFloat bpm = PHSys().bpm;
  if (bpm > 0) {
    _tapBpmLabel.layer.hidden = NO;
    _tapBpmLabel.stringValue = [NSString stringWithFormat:@"bpm: %.0f", [PHSys() bpm]];
    [_tapBpmLabel sizeToFit];

    _tapBpmLabel.frame = CGRectMake(self.bounds.size.width - _tapBpmLabel.frame.size.width, 0, _tapBpmLabel.frame.size.width, _tapBpmLabel.frame.size.height);
  } else {
    _tapBpmLabel.layer.hidden = YES;
  }

  self.layer.backgroundColor = PHSys().isBeating ? [NSColor colorWithDeviceWhite:0 alpha:0.1].CGColor : [NSColor clearColor].CGColor;
}

#pragma mark - PHListViewDelegate

- (void)listView:(PHListView *)listView didSelectRowAtIndex:(NSInteger)index {
  if (listView == _categoriesView) {
    [PHSys() setActiveCategory:_categories[index]];

  } else if (listView == _transitionsView) {
    PHSys().faderTransition = _transitions[index];
  }
}

#pragma mark - PHListViewDataSource

- (NSInteger)numberOfRowsInListView:(PHListView *)listView {
  if (listView == _categoriesView) {
    return _categories.count;
  } else if (listView == _transitionsView) {
    return _transitions.count;
  } else {
    return 0;
  }
}

- (NSString *)listView:(PHListView *)listView stringForRowAtIndex:(NSInteger)index {
  if (listView == _categoriesView) {
    return _categories[index];
  } else if (listView == _transitionsView) {
    return [_transitions[index] tooltipName];
  } else {
    return nil;
  }
}

#pragma mark - NSNotification

- (void)activeCategoryDidChangeNotification:(NSNotification *)notification {
  [_categoriesView setSelectedIndex:[_categories indexOfObject:[PHSys() activeCategory]]];
}

- (void)displayLinkDidFire:(NSNotification *)notification {
  if ([NSThread currentThread] != [NSThread mainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self updateBpm];
    });
  } else {
    [self updateBpm];
  }
}

@end
