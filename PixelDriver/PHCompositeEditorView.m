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

#import "PHCompositeEditorView.h"

#import "PHAnimation.h"
#import "PHAnimationTileView.h"
#import "PHAnimationCollectionView.h"
#import "PHAnimationTileViewItem.h"
#import "PHCompositeAnimation.h"
#import "PHCollectionView.h"
#import "PHButton.h"
#import "PHListView.h"
#import "PHWallView.h"
#import "PHSystem.h"
#import "AppDelegate.h"

static const NSEdgeInsets kButtonMargins = {5, 5, 5, 5};
static const CGFloat kCompositesListWidth = 150;
static const CGFloat kPreviewPaneWidth = 200;

@interface PHCompositeEditorView() <PHButtonDelegate, PHListViewDelegate, PHListViewDataSource>
@end

@implementation PHCompositeEditorView {
  PHButton* _newButton;
  PHButton* _deleteButton;
  PHButton* _renameButton;
  PHListView* _compositesView;
  NSArray* _composites;

  PHContainerView* _previewCompositeView;

  PHContainerView* _layersContainerView;
  PHAnimationCollectionView* _layersView;
  NSIndexSet* _previousSelectionIndexes;
}

- (void)dealloc {
  [_layersView removeObserver:self forKeyPath:@"selectionIndexes"];

  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    _composites = [PHSys().compositeAnimations copy];

    // Preview vizualization
    _previewCompositeView = [[PHContainerView alloc] initWithFrame:NSZeroRect];
    [self addSubview:_previewCompositeView];

    PHWallView* wallView = [[PHWallView alloc] initWithFrame:_previewCompositeView.contentView.bounds];
    wallView.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
    wallView.systemContext = PHSystemContextCompositePreview;
    [_previewCompositeView.contentView addSubview:wallView];

    _compositesView = [[PHListView alloc] init];
    _compositesView.tag = PHSystemComposites;
    _compositesView.title = @"Composites";
    _compositesView.dataSource = self;
    _compositesView.delegate = self;
    [self addSubview:_compositesView];

    // Buttons
    _newButton = [[PHButton alloc] init];
    _newButton.tag = PHSystemButtonNewComposite;
    _newButton.delegate = self;
    [_newButton setTitle:@"New"];
    [self addSubview:_newButton];

    _renameButton = [[PHButton alloc] init];
    _renameButton.tag = PHSystemButtonRenameComposite;
    _renameButton.delegate = self;
    [_renameButton setTitle:@"Rename"];
    [self addSubview:_renameButton];

    _deleteButton = [[PHButton alloc] init];
    _deleteButton.tag = PHSystemButtonDeleteComposite;
    _deleteButton.delegate = self;
    [_deleteButton setTitle:@"Delete"];
    [self addSubview:_deleteButton];

    // Layer Views
    _layersContainerView = [[PHContainerView alloc] init];
    [self addSubview:_layersContainerView];

    _layersView = [[PHAnimationCollectionView alloc] init];
    _layersView.isDragSource = YES;
    _layersView.isDragDestination = YES;
    _layersView.tag = PHSystemCompositeLayers;
    _layersView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _layersView.itemPrototype = [PHAnimationTileViewItem new];
    [_layersView setSelectable:YES];
    _layersView.backgroundColors = @[
                                     [NSColor colorWithDeviceWhite:0.2 alpha:1],
                                     [NSColor colorWithDeviceWhite:0.15 alpha:1],
                                     ];
    _layersView.allowsMultipleSelection = NO;
    [_layersContainerView.contentView addSubview:_layersView];

    [_layersView setSelectionIndexes:[NSIndexSet indexSetWithIndex:0]];

    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(compositesDidChangeNotification:) name:PHSystemCompositesDidChangeNotification object:nil];
    [nc addObserver:self selector:@selector(activeCompositeDidChangeNotification:) name:PHSystemActiveCompositeDidChangeNotification object:nil];

    [self compositeDidChange];

    [_layersView addObserver:self
                      forKeyPath:@"selectionIndexes"
                         options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
                         context:NULL];
    [_layersView setSelectionIndexes:[NSIndexSet indexSetWithIndex:0]];
  }
  return self;
}

- (void)layout {
  [super layout];

  [_newButton sizeToFit];
  [_deleteButton sizeToFit];
  [_renameButton sizeToFit];

  CGFloat topEdge = self.bounds.size.height;

  _newButton.frame = CGRectMake(kButtonMargins.left, topEdge - _newButton.frame.size.height - kButtonMargins.top, _newButton.frame.size.width, _newButton.frame.size.height);
  _renameButton.frame = CGRectMake(kButtonMargins.left, _newButton.frame.origin.y - kButtonMargins.bottom - _renameButton.frame.size.height, _renameButton.frame.size.width, _renameButton.frame.size.height);
  _deleteButton.frame = CGRectMake(kButtonMargins.left, _renameButton.frame.origin.y - kButtonMargins.bottom - _deleteButton.frame.size.height, _deleteButton.frame.size.width, _deleteButton.frame.size.height);

  CGFloat buttonRightEdge = MAX(MAX(CGRectGetMaxX(_newButton.frame),
                                    CGRectGetMaxX(_deleteButton.frame)),
                                CGRectGetMaxX(_renameButton.frame)) + kButtonMargins.right;

  CGRect frame = _newButton.frame;
  frame.origin.x = floorf((buttonRightEdge - frame.size.width) / 2);
  _newButton.frame = frame;

  frame = _deleteButton.frame;
  frame.origin.x = floorf((buttonRightEdge - frame.size.width) / 2);
  _deleteButton.frame = frame;

  frame = _renameButton.frame;
  frame.origin.x = floorf((buttonRightEdge - frame.size.width) / 2);
  _renameButton.frame = frame;

  _compositesView.frame = CGRectMake(buttonRightEdge, 0, kCompositesListWidth, topEdge);
  [_compositesView layout];

  CGFloat visualizerAspectRatio = (CGFloat)kWallHeight / (CGFloat)kWallWidth;
  CGFloat previewHeight = kPreviewPaneWidth * visualizerAspectRatio;
  _previewCompositeView.frame = CGRectMake(self.bounds.size.width - kPreviewPaneWidth,
                                           floor((topEdge - previewHeight) / 2),
                                           kPreviewPaneWidth, previewHeight);

  CGFloat layerViewsLeftEdge = CGRectGetMaxX(_compositesView.frame);
  CGFloat layerViewsRightEdge = CGRectGetMinX(_previewCompositeView.frame);
  _layersContainerView.frame = CGRectMake(layerViewsLeftEdge, 0, layerViewsRightEdge - layerViewsLeftEdge, self.bounds.size.height);

  NSInteger halfway = PHNumberOfCompositeLayers / 2;
  CGFloat layerViewWidth = floor(_layersContainerView.contentView.frame.size.width / (CGFloat)halfway);

  CGFloat layerHeight = layerViewWidth * visualizerAspectRatio;
  CGFloat halfHeight = _layersContainerView.contentView.frame.size.height / 2;

  CGFloat leftEdge = 0;
  topEdge = 0;
  if (layerHeight > halfHeight) {
    layerHeight = halfHeight;
    layerViewWidth = layerHeight / visualizerAspectRatio;

    leftEdge = floorf((_layersContainerView.contentView.frame.size.width - layerViewWidth * halfway) / 2);

  } else if (layerHeight < halfHeight) {
    topEdge = floorf((_layersContainerView.contentView.frame.size.height - layerHeight * 2) / 2);
  }

  CGSize itemSize = CGSizeMake(layerViewWidth, layerHeight);
  _layersView.minItemSize = itemSize;
  _layersView.maxItemSize = itemSize;

  CGFloat shrinkAmountX = leftEdge + _layersContainerView.contentView.frame.origin.x;
  CGFloat shrinkAmountY = topEdge + _layersContainerView.contentView.frame.origin.y;
  frame = _layersContainerView.frame;
  frame.origin.x += shrinkAmountX;
  frame.size.width -= shrinkAmountX * 2;
  frame.origin.y += shrinkAmountY;
  frame.size.height -= shrinkAmountY * 2;
  _layersContainerView.frame = frame;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if (_layersView == object) {
    if (_layersView.selectionIndexes.count == 0) {
      if (_previousSelectionIndexes.count > 0) {
        _layersView.selectionIndexes = _previousSelectionIndexes;
      }
    } else {
      _previousSelectionIndexes = [_layersView.selectionIndexes copy];
      [self compositeDidChange];

      PHSys().activeCompositeLayer = [_layersView.selectionIndexes firstIndex];
    }
  }
}

#pragma mark - PHListViewDelegate

- (void)listView:(PHListView *)listView didSelectRowAtIndex:(NSInteger)index {
  if (listView == _compositesView) {
    PHSys().editingCompositeAnimation = _composites[index];
    [self compositeDidChange];

    [_layersView setSelectionIndexes:[NSIndexSet indexSetWithIndex:0]];
  }
}

#pragma mark - PHListViewDataSource

- (NSInteger)numberOfRowsInListView:(PHListView *)listView {
  if (listView == _compositesView) {
    return _composites.count;
  } else {
    return 0;
  }
}

- (NSString *)listView:(PHListView *)listView stringForRowAtIndex:(NSInteger)index {
  if (listView == _compositesView) {
    return [_composites[index] tooltipName];
  } else {
    return nil;
  }
}

#pragma mark - PHButtonDelegate

- (void)didPressDownButton:(PHButton *)button {
  [PHSys() didPressButton:(PHSystemControlIdentifier)button.tag];
}

- (void)didReleaseButton:(PHButton *)button {
  [PHSys() didReleaseButton:(PHSystemControlIdentifier)button.tag];
}

#pragma mark - NSNotifications

- (void)compositesDidChangeNotification:(NSNotification *)notification {
  _composites = [PHSys().compositeAnimations copy];
  [_compositesView reloadData];

  PHCompositeAnimation *editingAnimation = PHSys().editingCompositeAnimation;
  if (nil != editingAnimation) {
    NSInteger indexOfEditingComposite = [_composites indexOfObject:editingAnimation];
    [_compositesView setSelectedIndex:indexOfEditingComposite];
  }

  [self compositeDidChange];
}

- (void)activeCompositeDidChangeNotification:(NSNotification *)notification {
  [self compositeDidChange];
}

#pragma mark - Private Methods

- (void)compositeDidChange {
  _layersView.content = [PHSys().editingCompositeAnimation layers];
}

@end
