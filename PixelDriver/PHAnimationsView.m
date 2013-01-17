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

#import "PHAnimation.h"

static NSString* const kIndexColumnIdentifier = @"indexColumn";
static NSString* const kNameColumnIdentifier = @"nameColumn";
static NSString* const kScreenshotColumnIdentifier = @"screenshotColumn";

@interface PHAnimationTableHeaderCell : NSTableHeaderCell
@end

@implementation PHAnimationTableHeaderCell

- (void)drawWithFrame:(NSRect)cellFrame {
  if (self.state == 1) {
    NSColor* startingColor = [NSColor colorWithDeviceWhite:0.2 alpha:1];
    NSColor* endingColor = [NSColor colorWithDeviceWhite:0.25 alpha:1];
    NSGradient *grad = [[NSGradient alloc] initWithStartingColor:startingColor endingColor:endingColor];
    [grad drawInRect:cellFrame angle:90];

  } else {
    NSColor* startingColor = [NSColor colorWithDeviceWhite:0.25 alpha:1];
    NSColor* endingColor = [NSColor colorWithDeviceWhite:0.2 alpha:1];
    NSGradient *grad = [[NSGradient alloc] initWithStartingColor:startingColor endingColor:endingColor];
    [grad drawInRect:cellFrame angle:90];
  }

  [[NSColor colorWithDeviceWhite:0.1 alpha:1] setFill];
  CGRect border = cellFrame;
  border.size.height = 1;
  border.origin.y = cellFrame.size.height - 1;
  NSRectFillUsingOperation(border, NSCompositeCopy);

  NSDictionary* attributes = @{
    NSForegroundColorAttributeName:[NSColor colorWithDeviceWhite:0.6 alpha:1],
    NSFontAttributeName:[NSFont boldSystemFontOfSize:11]
  };
  NSMutableAttributedString* string = [[NSMutableAttributedString alloc] initWithString:self.stringValue attributes:attributes];
  [string drawInRect:CGRectOffset(CGRectInset(cellFrame, 5, 0), 0, 1)];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  [self drawWithFrame:cellFrame];
}

@end

@interface PHAnimationCell : NSTextFieldCell
@end

@implementation PHAnimationCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  NSDictionary* attributes = @{
    NSForegroundColorAttributeName:[NSColor colorWithDeviceWhite:0.8 alpha:1],
    NSFontAttributeName:[NSFont systemFontOfSize:12]
  };
  NSMutableAttributedString* string = [[NSMutableAttributedString alloc] initWithString:self.stringValue attributes:attributes];
  [string drawInRect:CGRectInset(cellFrame, 5, 0)];
}

@end

@interface PHAnimationTableView : NSTableView
@end

@implementation PHAnimationTableView {
  NSArray* _backgroundColors;
}

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    _backgroundColors = @[
    [NSColor colorWithDeviceWhite:0.2 alpha:1],
    [NSColor colorWithDeviceWhite:0.15 alpha:1],
    ];
  }
  return self;
}

- (void)drawBackgroundInClipRect:(NSRect)inClipRect {
  NSUInteger n = [_backgroundColors count];
  NSUInteger i = 0;

  CGFloat height = self.rowHeight + self.intercellSpacing.height;
  NSRect clipRect = [self bounds];
  NSRect drawRect = clipRect;
  drawRect.origin = NSZeroPoint;
  drawRect.size.height = height;

  [[self backgroundColor] set];
  NSRectFillUsingOperation(inClipRect,NSCompositeSourceOver);

  while ((NSMinY(drawRect) <= NSHeight(clipRect)))
  {
    if (NSIntersectsRect(drawRect,clipRect))
    {
      [[_backgroundColors objectAtIndex:i%n] setFill];
      NSRectFillUsingOperation(drawRect,NSCompositeSourceOver);
    }

    drawRect.origin.y += height;
    i++;
  }
}

@end

@interface PHAnimationsView() <NSTableViewDataSource, NSTableViewDelegate>
@end

@implementation PHAnimationsView {
  NSTableView* _tableView;
  NSScrollView* _scrollView;
  NSArray* _animations;
}

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    _tableView = [[PHAnimationTableView alloc] initWithFrame:self.contentView.bounds];
    _tableView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = PHBackgroundColor();

    NSTableColumn* indexColumn = [[NSTableColumn alloc] initWithIdentifier:kIndexColumnIdentifier];
    indexColumn.headerCell = [[PHAnimationTableHeaderCell alloc] initTextCell:@"#"];
    [_tableView addTableColumn:indexColumn];

    NSTableColumn* nameColumn = [[NSTableColumn alloc] initWithIdentifier:kNameColumnIdentifier];
    nameColumn.headerCell = [[PHAnimationTableHeaderCell alloc] initTextCell:@"Name"];
    [_tableView addTableColumn:nameColumn];

    NSTableColumn* screenshotColumn = [[NSTableColumn alloc] initWithIdentifier:kScreenshotColumnIdentifier];
    screenshotColumn.headerCell = [[PHAnimationTableHeaderCell alloc] initTextCell:@"Screenshot"];
    [_tableView addTableColumn:screenshotColumn];

    _scrollView = [[NSScrollView alloc] initWithFrame:self.contentView.bounds];
    _scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _scrollView.borderType = NSNoBorder;
    _scrollView.hasVerticalScroller = YES;
    _scrollView.hasHorizontalScroller = NO;
    _scrollView.autohidesScrollers = YES;
    _scrollView.scrollerKnobStyle = NSScrollerKnobStyleLight;

    _scrollView.documentView = _tableView;
    [self.contentView addSubview:_scrollView];

    _animations = [PHAnimation allAnimations];
  }
  return self;
}

- (void)layout {
  [super layout];

  [_tableView reloadData];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return _animations.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  if ([tableColumn.identifier isEqualToString:kIndexColumnIdentifier]) {
    return [NSString stringWithFormat:@"%ld", row + 1];
  }
  PHAnimation* animation = [_animations objectAtIndex:row];
  if ([tableColumn.identifier isEqualToString:kNameColumnIdentifier]) {
    return animation.tooltipName;
  }
  return nil;
}

- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  NSString* string = [self tableView:tableView objectValueForTableColumn:tableColumn row:row];
  if (nil != string) {
    return [[PHAnimationCell alloc] initTextCell:string];
  } else {
    return nil;
  }
}

@end
