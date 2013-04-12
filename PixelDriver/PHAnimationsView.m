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
#import "PHCompositeAnimation.h"
#import "PHSystem.h"
#import "PHScrollView.h"

@interface PHAnimationTileViewItem : NSCollectionViewItem
@end

@implementation PHAnimationTileViewItem

- (void)loadView {
  [self setView:[[PHAnimationTileView alloc] initWithFrame:NSZeroRect]];
}

- (void)setRepresentedObject:(id)representedObject {
  [super setRepresentedObject:representedObject];

  PHAnimationTileView* view = (PHAnimationTileView *)self.view;
  view.animation = representedObject;
  [view setNeedsDisplay:YES];
}

- (void)setSelected:(BOOL)selected {
  [super setSelected:selected];

  PHAnimationTileView* view = (PHAnimationTileView *)self.view;
  [view setSelected:selected];
  [view setNeedsDisplay:YES];
}

@end

@interface PHCollectionView : NSCollectionView
@end

@implementation PHCollectionView

- (id)animationForKey:(NSString *)key {
  return nil;
}

@end

@implementation PHAnimationsView {
  PHCollectionView* _collectionView;
  PHScrollView* _scrollView;
  NSArray* _animations;
  NSIndexSet* _previousSelectionIndexes;
}

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    _collectionView = [[PHCollectionView alloc] initWithFrame:self.contentView.bounds];
    _collectionView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _collectionView.itemPrototype = [PHAnimationTileViewItem new];
    [_collectionView setSelectable:YES];
    _collectionView.backgroundColors = @[
      [NSColor colorWithDeviceWhite:0.2 alpha:1],
      [NSColor colorWithDeviceWhite:0.15 alpha:1],
    ];
    _collectionView.allowsMultipleSelection = NO;
    _collectionView.minItemSize = CGSizeMake(186, 124);
    _collectionView.maxItemSize = CGSizeMake(450, 300);

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

    _animations = [PHSys().compiledAnimations copy];
    _collectionView.content = _animations;

    [_collectionView addObserver:self
                      forKeyPath:@"selectionIndexes"
                         options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
                         context:NULL];
    [_collectionView setSelectionIndexes:[NSIndexSet indexSetWithIndex:0]];

    [self setCategoryFilter:@"All"];
  }
  return self;
}

- (void)updateSystemWithSelection {
  PHAnimation* selectedAnimation = _collectionView.content[[_previousSelectionIndexes firstIndex]];
  PHSys().previewAnimation = selectedAnimation;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if (_collectionView == object) {
    if (_collectionView.selectionIndexes.count == 0) {
      _collectionView.selectionIndexes = _previousSelectionIndexes;
    } else {
      _previousSelectionIndexes = [_collectionView.selectionIndexes copy];
      [self updateSystemWithSelection];
    }
  }
}

- (void)setCategoryFilter:(NSString *)category {
  if ([category isEqualToString:@"All"]) {
    NSMutableArray* filteredArray = [NSMutableArray array];
    for (PHAnimation* animation in _animations) {
      if (![animation.categories containsObject:PHAnimationCategoryPipes]) {
        [filteredArray addObject:animation];
      }
    }
    _collectionView.content = filteredArray;

  } else {
    NSMutableArray* filteredArray = [NSMutableArray array];
    for (PHAnimation* animation in _animations) {
      if ([category isEqualToString:PHAnimationCategoryPipes]
          && [animation isKindOfClass:[PHCompositeAnimation class]]) {
        continue;
      }
      if ([animation.categories containsObject:category]) {
        [filteredArray addObject:animation];
      }
    }
    _collectionView.content = filteredArray;
  }
}

- (PHAnimation *)selectedAnimation {
  return _collectionView.content[[_previousSelectionIndexes firstIndex]];
}

@end
