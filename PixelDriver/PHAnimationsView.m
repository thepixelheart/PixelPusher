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

@interface PHAnimationCell : NSTextFieldCell
@property (nonatomic, copy) NSString* name;
@end

@implementation PHAnimationCell

- (id)copyWithZone:(NSZone *)zone {
  PHAnimationCell* cell = [super copyWithZone:zone];
  if (nil == cell) {
    return nil;
  }
  cell->_name = [_name copyWithZone:zone];
  return cell;
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
    _tableView = [[NSTableView alloc] initWithFrame:self.contentView.bounds];
    _tableView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = PHBackgroundColor();

    NSTableColumn* indexColumn = [[NSTableColumn alloc] initWithIdentifier:kIndexColumnIdentifier];
    [indexColumn.headerCell setStringValue:@"#"];
    [_tableView addTableColumn:indexColumn];

    NSTableColumn* nameColumn = [[NSTableColumn alloc] initWithIdentifier:kNameColumnIdentifier];
    [nameColumn.headerCell setStringValue:@"Name"];
    [_tableView addTableColumn:nameColumn];

    NSTableColumn* screenshotColumn = [[NSTableColumn alloc] initWithIdentifier:kScreenshotColumnIdentifier];
    [screenshotColumn.headerCell setStringValue:@"Screenshot"];
    [_tableView addTableColumn:screenshotColumn];

    _scrollView = [[NSScrollView alloc] initWithFrame:self.contentView.bounds];
    _scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _scrollView.borderType = NSNoBorder;
    _scrollView.hasVerticalScroller = YES;
    _scrollView.hasHorizontalScroller = NO;
    _scrollView.autohidesScrollers = YES;

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
    return [NSString stringWithFormat:@"%ld", row];
  }
  PHAnimation* animation = [_animations objectAtIndex:row];
  if ([tableColumn.identifier isEqualToString:kNameColumnIdentifier]) {
    return animation.tooltipName;
  }
  return nil;
}

@end
