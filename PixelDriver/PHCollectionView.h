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

#import <Cocoa/Cocoa.h>

extern NSString* const kAnimationKey;

@class PHAnimation;
@protocol PHCollectionViewDragDestinationDelegate;

@interface PHCollectionView : NSCollectionView
@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, assign) BOOL isDragSource; // Default NO
@property (nonatomic, assign) BOOL isDragDestination; // Default NO
@property (nonatomic, weak) id<PHCollectionViewDragDestinationDelegate> dragDestinationDelegate;
@end

@protocol PHCollectionViewDragDestinationDelegate <NSObject>
@required

- (void)collectionView:(PHCollectionView *)collectionView didDropAnimation:(PHAnimation *)animation atIndex:(NSInteger)index;
- (void)collectionView:(PHCollectionView *)collectionView didMoveAnimation:(PHAnimation *)animation fromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;

@end
