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

#import "PHAnimationsView.h"

#import "AppDelegate.h"
#import "PHAnimation.h"
#import "PHAnimationTileView.h"
#import "PHAnimationTileViewItem.h"
#import "PHCollectionView.h"
#import "PHCompositeAnimation.h"
#import "PHSystem.h"
#import "PHScrollView.h"

@implementation PHAnimationsView {
  PHCollectionView* _collectionView;
  PHScrollView* _scrollView;
  NSArray* _animations;
  NSIndexSet* _previousSelectionIndexes;
  NSString* _categoryFilter;
  BOOL _isSettingPreview;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    _collectionView = [[PHCollectionView alloc] initWithFrame:self.contentView.bounds];
    _collectionView.isDragSource = YES;
    _collectionView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _collectionView.itemPrototype = [PHAnimationTileViewItem new];
    [_collectionView setSelectable:YES];
    _collectionView.backgroundColors = @[
      [NSColor colorWithDeviceWhite:0.2 alpha:1],
      [NSColor colorWithDeviceWhite:0.15 alpha:1],
    ];
    _collectionView.allowsMultipleSelection = NO;
    _collectionView.minItemSize = CGSizeMake(48 * 3, 32 * 3);
    _collectionView.maxItemSize = CGSizeMake(48 * 5, 32 * 5);

    [_collectionView setSelectionIndexes:[NSIndexSet indexSetWithIndex:0]];

    _scrollView = [[PHScrollView alloc] initWithFrame:self.contentView.bounds];
    _scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _scrollView.tag = PHSystemAnimations;
    _scrollView.borderType = NSNoBorder;
    _scrollView.hasVerticalScroller = YES;
    _scrollView.hasHorizontalScroller = NO;
    _scrollView.autohidesScrollers = YES;
    _scrollView.scrollerKnobStyle = NSScrollerKnobStyleLight;
    _scrollView.backgroundColor = PHBackgroundColor();

    _scrollView.documentView = _collectionView;
    [self.contentView addSubview:_scrollView];

    _animations = [self allAnimations];
    _collectionView.content = _animations;

    [_collectionView addObserver:self
                      forKeyPath:@"selectionIndexes"
                         options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
                         context:NULL];

    [self updateCollection];

    [_collectionView setSelectionIndexes:[NSIndexSet indexSetWithIndex:0]];

    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(compositesDidChangeNotification:) name:PHSystemCompositesDidChangeNotification object:nil];
    [nc addObserver:self selector:@selector(activeCompositeDidChangeNotification:) name:PHSystemActiveCompositeDidChangeNotification object:nil];
    [nc addObserver:self selector:@selector(activeCategoryDidChangeNotification:) name:PHSystemActiveCategoryDidChangeNotification object:nil];
    [nc addObserver:self selector:@selector(previewAnimationDidChangeNotification:) name:PHSystemPreviewAnimationDidChangeNotification object:nil];
  }
  return self;
}

- (NSArray *)allAnimations {
  return [PHSys().compiledAnimations arrayByAddingObjectsFromArray:PHSys().compositeAnimations];
}

- (void)updateSystemWithSelection {
  _isSettingPreview = YES;
  PHAnimation* selectedAnimation = _collectionView.content[[_previousSelectionIndexes firstIndex]];
  PHSys().previewAnimation = selectedAnimation;
  _isSettingPreview = NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if (_collectionView == object) {
    if (_collectionView.selectionIndexes.count == 0) {
      if (_previousSelectionIndexes.count > 0) {
        _collectionView.selectionIndexes = _previousSelectionIndexes;
      }
    } else {
      _previousSelectionIndexes = [_collectionView.selectionIndexes copy];
      [self updateSystemWithSelection];
    }
  }
}

- (PHAnimation *)selectedAnimation {
  return _collectionView.content[[_previousSelectionIndexes firstIndex]];
}

- (void)updateCollection {
  _animations = [PHSys() filteredAnimations];
  _collectionView.content = _animations;
}

#pragma mark - NSNotifications

- (void)compositesDidChangeNotification:(NSNotification *)notification {
  [self updateCollection];
}

- (void)activeCompositeDidChangeNotification:(NSNotification *)notification {
  
}

- (void)activeCategoryDidChangeNotification:(NSNotification *)notification {
  [self updateCollection];
}

- (void)previewAnimationDidChangeNotification:(NSNotification *)notification {
  NSInteger selectionIndex = [_animations indexOfObject:[PHSys() previewAnimation]];
  if (selectionIndex != NSNotFound) {
    NSIndexSet *selection = [NSIndexSet indexSetWithIndex:selectionIndex];
    if (selection.firstIndex >= _collectionView.content.count) {
      selection = [NSIndexSet indexSetWithIndex:_collectionView.content.count - 1];
    }
    if (!_isSettingPreview) {
      CGRect selectionFrame = [_collectionView frameForItemAtIndex:selection.firstIndex];
      CGPoint offset = CGPointMake(0, selectionFrame.origin.y - _scrollView.bounds.size.height / 2);
      offset.y = MAX(0, MIN(_collectionView.frame.size.height - _scrollView.bounds.size.height, offset.y));
      [_scrollView.contentView scrollToPoint:offset];
      _collectionView.selectionIndexes = selection;
    }

    _previousSelectionIndexes = selection;
  }
}

@end
