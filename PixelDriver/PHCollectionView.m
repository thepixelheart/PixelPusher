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

#import "PHCollectionView.h"

#import "PHAnimation.h"

static NSString* const kAnimationKey = @"kAnimationKey";
static NSString* const kSourceIndexKey = @"kSourceIndexKey";
static NSString* const kSourceTagKey = @"kSourceTagKey";

@interface PHCollectionView () <NSCollectionViewDelegate, NSDraggingDestination>
@end

@implementation PHCollectionView

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    self.delegate = self;
    [self setDraggingSourceOperationMask:NSDragOperationGeneric forLocal:YES];
  }
  return self;
}

- (id)animationForKey:(NSString *)key {
  return nil;
}

- (void)setIsDragDestination:(BOOL)isDragDestination {
  _isDragDestination = isDragDestination;

  if (_isDragDestination) {
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSPasteboardTypeString, nil]];
  } else {
    [self unregisterDraggedTypes];
  }
}

#pragma mark - NSDraggingDestination

#pragma mark - NSCollectionViewDelegate

- (BOOL)collectionView:(NSCollectionView *)cv writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard {
  if (self.isDragSource && indexes.count == 1) {
    PHAnimation* animation = cv.content[indexes.firstIndex];
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:animation forKey:kAnimationKey];
    [archiver encodeObject:@(indexes.firstIndex) forKey:kSourceIndexKey];
    [archiver encodeObject:@(self.tag) forKey:kSourceTagKey];
    [archiver finishEncoding];

    [pasteboard setData:data forType:NSStringPboardType];
    return YES;
  }
  return NO;
}

- (BOOL)collectionView:(NSCollectionView *)collectionView
            acceptDrop:(id <NSDraggingInfo>)draggingInfo
                 index:(NSInteger)index
         dropOperation:(NSCollectionViewDropOperation)dropOperation {
  if (!_isDragDestination) {
    return NO;
  }

  NSPasteboard *pboard;
  NSDragOperation sourceDragMask;

  sourceDragMask = [draggingInfo draggingSourceOperationMask];
  pboard = [draggingInfo draggingPasteboard];

  if ([[pboard types] containsObject:NSStringPboardType] ) {
    NSData *data = [pboard dataForType:NSStringPboardType];

    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    PHAnimation *animation = [unarchiver decodeObjectForKey:kAnimationKey];
    NSInteger sourceTag = [[unarchiver decodeObjectForKey:kSourceTagKey] intValue];
    if (sourceTag == self.tag) {
      NSInteger sourceIndex = [[unarchiver decodeObjectForKey:kSourceIndexKey] intValue];
      [_dragDestinationDelegate collectionView:self didMoveAnimation:animation fromIndex:sourceIndex toIndex:index];

    } else {
      [_dragDestinationDelegate collectionView:self didDropAnimation:animation atIndex:index];
    }
  }

  return YES;
}

- (NSDragOperation)collectionView:(NSCollectionView *)collectionView
                     validateDrop:(id <NSDraggingInfo>)draggingInfo
                    proposedIndex:(NSInteger *)proposedDropIndex
                    dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation {
  if (*proposedDropOperation == NSCollectionViewDropBefore) {
    *proposedDropOperation = NSCollectionViewDropOn;
    *proposedDropIndex = (*proposedDropIndex) - 1;
  }
  return NSDragOperationGeneric;
}

@end
