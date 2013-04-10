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

#import "PHButton.h"
#import "PHListView.h"
#import "PHSystem.h"
#import "AppDelegate.h"

static const CGFloat kCompositesListWidth = 150;

@interface PHCompositeEditorView() <PHButtonDelegate, PHListViewDelegate, PHListViewDataSource>
@end

@implementation PHCompositeEditorView {
  PHButton* _newButton;
  PHListView* _compositesView;
}

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    _compositesView = [[PHListView alloc] init];
    _compositesView.tag = PHSystemComposites;
    _compositesView.title = @"Composites";
    _compositesView.dataSource = self;
    _compositesView.delegate = self;
    [self addSubview:_compositesView];

    _newButton = [[PHButton alloc] init];
    _newButton.tag = PHSystemButtonNewComposite;
    _newButton.delegate = self;
    [_newButton setTitle:@"New"];
    [self addSubview:_newButton];
  }
  return self;
}

- (void)layout {
  [super layout];

  [_newButton sizeToFit];

  CGFloat topEdge = self.bounds.size.height;

  _newButton.frame = CGRectMake(0, topEdge - _newButton.frame.size.height, _newButton.frame.size.width, _newButton.frame.size.height);
  _compositesView.frame = CGRectMake(_newButton.frame.size.width, 0, kCompositesListWidth, topEdge);
  [_compositesView layout];
}

#pragma mark - PHListViewDelegate

- (void)listView:(PHListView *)listView didSelectRowAtIndex:(NSInteger)index {
  if (listView == _compositesView) {
  }
}

#pragma mark - PHListViewDataSource

- (NSInteger)numberOfRowsInListView:(PHListView *)listView {
  if (listView == _compositesView) {
    return 2;
  } else {
    return 0;
  }
}

- (NSString *)listView:(PHListView *)listView stringForRowAtIndex:(NSInteger)index {
  if (listView == _compositesView) {
    return @"Composite";
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

@end
