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

#import "PHListView.h"

#import "PHAnimation.h"

@interface PHListCell : NSTextFieldCell
@end

@implementation PHListCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  if (self.isHighlighted) {
    [[NSColor blackColor] set];
    NSRectFill(cellFrame);
  }
  NSDictionary* attributes = @{
    NSForegroundColorAttributeName:[NSColor colorWithDeviceWhite:0.8 alpha:1],
    NSFontAttributeName:[NSFont systemFontOfSize:12]
  };
  NSMutableAttributedString* string = [[NSMutableAttributedString alloc] initWithString:self.stringValue attributes:attributes];
  [string drawInRect:CGRectInset(cellFrame, 5, 0)];
}

@end

@interface PHListTableView : NSTableView
@end

@implementation PHListTableView {
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

  while ((NSMinY(drawRect) <= NSHeight(clipRect))) {
    if (NSIntersectsRect(drawRect,clipRect)) {
      [[_backgroundColors objectAtIndex:i%n] setFill];
      NSRectFillUsingOperation(drawRect,NSCompositeSourceOver);
    }

    drawRect.origin.y += height;
    i++;
  }
}

@end

@interface PHListView() <NSTableViewDataSource, NSTableViewDelegate>
@end

@implementation PHListView {
  NSTableView* _tableView;
  NSScrollView* _scrollView;

  NSInteger _previousSelectedRow;
}

- (void)dealloc {
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc removeObserver:self];
}

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    _tableView = [[PHListTableView alloc] initWithFrame:self.contentView.bounds];
    _tableView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _tableView.headerView = nil;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = PHBackgroundColor();

    _scrollView = [[NSScrollView alloc] initWithFrame:self.contentView.bounds];
    _scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _scrollView.borderType = NSNoBorder;
    _scrollView.hasVerticalScroller = YES;
    _scrollView.hasHorizontalScroller = NO;
    _scrollView.autohidesScrollers = YES;
    _scrollView.scrollerKnobStyle = NSScrollerKnobStyleLight;

    _scrollView.documentView = _tableView;
    [self.contentView addSubview:_scrollView];

    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(didChangeSelectionNotification:) name:NSTableViewSelectionDidChangeNotification object:_tableView];
  }
  return self;
}

- (void)layout {
  [super layout];

  [_tableView reloadData];
  [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:_previousSelectedRow]
          byExtendingSelection:NO];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return [_dataSource numberOfRowsInListView:self];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  return [_dataSource listView:self stringForRowAtIndex:row];
}

- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  NSString* string = [self tableView:tableView objectValueForTableColumn:tableColumn row:row];
  if (nil != string) {
    return [[PHListCell alloc] initTextCell:string];
  } else {
    return nil;
  }
}

#pragma mark - Selection

- (void)didChangeSelectionNotification:(NSNotification *)notification {
  [_tableView becomeFirstResponder];
  if (_tableView.selectedRow < 0 || _tableView.selectedRow > [_dataSource numberOfRowsInListView:self]) {
    [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:_previousSelectedRow]
            byExtendingSelection:NO];

  } else if (_previousSelectedRow != _tableView.selectedRow) {
    [_delegate listView:self didSelectRowAtIndex:_tableView.selectedRow];
    _previousSelectedRow = _tableView.selectedRow;
  }
}

@end
