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
#import "PHCompositeAnimation.h"
#import "PHSystem.h"
#import "PHScrollView.h"

@interface PHAnimationTileView : NSView
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, copy) PHAnimation* animation;
@end

@implementation PHAnimationTileView {
  CGImageRef _previewImageRef;
}

- (void)dealloc {
  if (nil != _previewImageRef) {
    CGImageRelease(_previewImageRef);
    _previewImageRef = nil;
  }
}

- (id)initWithFrame:(NSRect)frameRect {
  CGFloat aspectRatio = (CGFloat)kWallWidth / (CGFloat)kWallHeight;
  self = [super initWithFrame:(NSRect){frameRect.origin, CGSizeMake(150 * aspectRatio, 150)}];
  if (self) {
  }
  return self;
}

- (void)drawRect:(NSRect)dirtyRect {
  if (_selected) {
    [[NSColor colorWithDeviceWhite:1 alpha:0.2] set];
    NSRectFill([self bounds]);
  }

  if (nil == _previewImageRef) {
    CGSize wallSize = CGSizeMake(kWallWidth, kWallHeight);
    CGContextRef contextRef = PHCreate8BitBitmapContextWithSize(wallSize);
    [_animation renderPreviewInContext:contextRef size:wallSize];

    _previewImageRef = CGBitmapContextCreateImage(contextRef);
    CGContextRelease(contextRef);
  }

  CGContextRef cx = [[NSGraphicsContext currentContext] graphicsPort];
  CGContextSaveGState(cx);
  CGContextScaleCTM(cx, 1, -1);
  CGContextTranslateCTM(cx, 0, -self.bounds.size.height);

  if (_selected) {
    CGContextSetAlpha(cx, 1);
  } else {
    CGContextSetAlpha(cx, 0.5);
  }

  CGContextSetInterpolationQuality(cx, kCGInterpolationNone);
  CGRect insetBounds = CGRectInset(self.bounds, 5, 5);
  CGFloat aspectRatio = (CGFloat)kWallHeight / (CGFloat)kWallWidth;
  CGFloat width = insetBounds.size.width;
  CGFloat height = width * aspectRatio;
  if (height > insetBounds.size.height) {
    height = insetBounds.size.height;
    width = height / aspectRatio;
  }
  CGContextDrawImage(cx, CGRectMake(insetBounds.origin.x + floor((insetBounds.size.width - width) / 2),
                                    insetBounds.origin.y + floor((insetBounds.size.height - height) / 2),
                                    width, height), _previewImageRef);
  CGContextRestoreGState(cx);

  NSDictionary* attributes = @{
    NSForegroundColorAttributeName:[NSColor colorWithDeviceWhite:_selected ? 1.0 : 0.6 alpha:1],
    NSFontAttributeName:[NSFont boldSystemFontOfSize:11]
  };
  NSMutableAttributedString* string = [[NSMutableAttributedString alloc] initWithString:_animation.tooltipName attributes:attributes];
  [string setAlignment:NSCenterTextAlignment range:NSMakeRange(0, string.length)];
  CGRect textFrame = CGRectInset(self.bounds, 5, 5);
  CGSize size = [string.string sizeWithAttributes:attributes];
  textFrame.size.height = size.height;

  CGContextSetRGBFillColor(cx, 0, 0, 0, 0.6);
  CGContextFillRect(cx, CGRectMake(0, 0, self.bounds.size.width, size.height + 10));

  [string drawInRect:textFrame];
}

- (void)setAnimation:(PHAnimation *)animation {
  if (_animation != animation) {
    _animation = [animation copy];

    if (nil != _previewImageRef) {
      CGImageRelease(_previewImageRef);
      _previewImageRef = nil;
    }
  }
}

@end

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

    _animations = [PHAnimation allAnimations];
    for (PHAnimation* animation in _animations) {
      animation.driver = PHApp().animationDriver;
    }
    _collectionView.content = _animations;

    [_collectionView addObserver:self
                      forKeyPath:@"selectionIndexes"
                         options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
                         context:NULL];
    [_collectionView setSelectionIndexes:[NSIndexSet indexSetWithIndex:0]];
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
    _collectionView.content = _animations;

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
