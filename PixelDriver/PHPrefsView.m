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

#import "PHPrefsView.h"

#import "PHListView.h"

static const CGFloat kExplorerWidth = 200;

@interface PHPrefsView() <PHListViewDelegate, PHListViewDataSource>
@end

@implementation PHPrefsView {
  PHListView* _pagesView;
}

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    _pagesView = [[PHListView alloc] init];
    _pagesView.title = @"Preferences";
    _pagesView.dataSource = self;
    _pagesView.delegate = self;
    [self addSubview:_pagesView];
  }
  return self;
}

- (void)layout {
  [super layout];

  CGSize boundsSize = self.bounds.size;
  _pagesView.frame = CGRectMake(0, 0, kExplorerWidth, boundsSize.height);
  [_pagesView layout];
}

#pragma mark - PHListViewDelegate

- (void)listView:(PHListView *)listView didSelectRowAtIndex:(NSInteger)index {
  if (listView == _pagesView) {
  }
}

#pragma mark - PHListViewDataSource

- (NSInteger)numberOfRowsInListView:(PHListView *)listView {
  if (listView == _pagesView) {
    return 1;
  } else {
    return 0;
  }
}

- (NSString *)listView:(PHListView *)listView stringForRowAtIndex:(NSInteger)index {
  if (listView == _pagesView) {
    return @"Hi";
  } else {
    return nil;
  }
}

@end
