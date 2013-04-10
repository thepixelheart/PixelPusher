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

#import "PHContainerView.h"

@protocol PHListViewDelegate;
@protocol PHListViewDataSource;

@interface PHListView : PHContainerView
@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, weak) id<PHListViewDelegate> delegate;
@property (nonatomic, weak) id<PHListViewDataSource> dataSource;

- (void)reloadData;
- (void)setSelectedIndex:(NSInteger)index;
@end

@protocol PHListViewDataSource <NSObject>
@required
- (NSInteger)numberOfRowsInListView:(PHListView *)listView;
- (NSString *)listView:(PHListView *)listView stringForRowAtIndex:(NSInteger)index;
@end

@protocol PHListViewDelegate <NSObject>
@required
- (void)listView:(PHListView *)listView didSelectRowAtIndex:(NSInteger)index;
@end
