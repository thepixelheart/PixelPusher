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

#import "PHAnimationTileView.h"

#import "PHCompositeAnimation.h"
#import "PHAnimation.h"
#import "PHSYstem.h"

@interface PHAnimationTileView() <NSDraggingSource, NSDraggingDestination, NSPasteboardItemDataProvider>
@end

@implementation PHAnimationTileView {
  CGImageRef _previewImageRef;
  BOOL _isDragDestination;
  BOOL _isDragSource;
  NSEvent *_mouseDownEvent;
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
  if (nil == _item.animation) {
    [[NSColor colorWithDeviceRed:0 green:0 blue:0 alpha:1] set];
    NSRectFill([self bounds]);
  }
  if (_selected) {
    [[NSColor colorWithDeviceWhite:1 alpha:0.2] set];
    NSRectFill([self bounds]);
  }

  if (nil == _previewImageRef && nil != _item.animation) {
    CGSize wallSize = CGSizeMake(kWallWidth, kWallHeight);
    CGContextRef contextRef = PHCreate8BitBitmapContextWithSize(wallSize);
    [_item.animation renderPreviewInContext:contextRef size:wallSize];

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

  if (_item.animation.tooltipName.length > 0) {
    NSDictionary* attributes = @{
      NSForegroundColorAttributeName:[NSColor colorWithDeviceWhite:_selected ? 1.0 : 0.6 alpha:1],
      NSFontAttributeName:[NSFont boldSystemFontOfSize:11]
    };
    NSMutableAttributedString* string = [[NSMutableAttributedString alloc] initWithString:_item.animation.tooltipName attributes:attributes];
    [string setAlignment:NSCenterTextAlignment range:NSMakeRange(0, string.length)];
    CGRect textFrame = CGRectInset(self.bounds, 5, 5);
    CGSize size = [string.string sizeWithAttributes:attributes];
    textFrame.size.height = size.height;

    CGContextSetRGBFillColor(cx, 0, 0, 0, 0.6);
    CGContextFillRect(cx, CGRectMake(0, 0, self.bounds.size.width, size.height + 10));

    [string drawInRect:textFrame];
  }
}

- (void)setItem:(PHAnimationCollectionViewItem *)item {
  if (_item != item) {
    _isDragDestination = item.isDragDestination;
    _isDragSource = item.isDragSource;

    if (item.isDragDestination) {
      [self registerForDraggedTypes:[NSArray arrayWithObjects:NSPasteboardTypeString, nil]];
    } else {
      [self unregisterDraggedTypes];
    }

    if (![item.animation isKindOfClass:[PHAnimation class]]) {
      item = nil;
    }
    _item = item;
  }

  if (nil != _previewImageRef) {
    CGImageRelease(_previewImageRef);
    _previewImageRef = nil;
  }
}

#pragma mark - NSDraggingSource

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
  if (!_isDragSource) {
    return NSDragOperationNone;
  }
  switch (context) {
    case NSDraggingContextOutsideApplication:
      return NSDragOperationNone;

    case NSDraggingContextWithinApplication:
    default:
      return NSDragOperationGeneric;
      break;
  }
}

- (void)pasteboard:(NSPasteboard *)sender item:(NSPasteboardItem *)item provideDataForType:(NSString *)type {
  if (!_isDragSource) {
    return;
  }

  if ([type compare:NSPasteboardTypeString] == NSOrderedSame) {
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:_item.animation];
    [archiver finishEncoding];

    [sender setData:data forType:NSStringPboardType];
  }
}

#pragma mark - NSDraggingDestination

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
  if (!_isDragDestination) {
    return NSDragOperationNone;
  }

  NSPasteboard *pboard;
  NSDragOperation sourceDragMask;

  sourceDragMask = [sender draggingSourceOperationMask];
  pboard = [sender draggingPasteboard];

  if ( [[pboard types] containsObject:NSStringPboardType] ) {
    if (sourceDragMask & NSDragOperationGeneric) {
      return NSDragOperationGeneric;
    }
  }
  return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
  if (!_isDragDestination) {
    return NO;
  }

  NSPasteboard *pboard;
  NSDragOperation sourceDragMask;

  sourceDragMask = [sender draggingSourceOperationMask];
  pboard = [sender draggingPasteboard];

  if ([[pboard types] containsObject:NSStringPboardType] ) {
    NSData *data = [pboard dataForType:NSStringPboardType];

    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    PHAnimation *animation = [unarchiver decodeObject];

    // TODO: For composite layers we need to store which index this is.
    // TODO: Tile view needs to store the composite animation.
    if ([_item.animation isKindOfClass:[PHCompositeAnimation class]]) {
      PHCompositeAnimation *composite = (PHCompositeAnimation *)_item.animation;
      [composite setAnimation:animation forLayer:0];
      NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
      [nc postNotificationName:PHSystemActiveCompositeDidChangeNotification object:nil];
    }
  }
  return YES;
}

#pragma mark - Dragging

- (void)mouseDown:(NSEvent *)event {
  [super mouseDown:event];

  if (_isDragSource) {
    _mouseDownEvent = event;
    [self performSelector:@selector(dragIfMouseStillDown) withObject:nil afterDelay:0.5];
  }
}

- (void)mouseUp:(NSEvent *)theEvent {
  [super mouseUp:theEvent];
  _mouseDownEvent = nil;
}

- (void)dragIfMouseStillDown {
  if (nil == _mouseDownEvent) {
    return;
  }
  NSPasteboardItem *pbItem = [NSPasteboardItem new];
  /* Our pasteboard item will support public.tiff, public.pdf, and our custom UTI (see comment in -draggingEntered)
   * representations of our data (the image).  Rather than compute both of these representations now, promise that
   * we will provide either of these representations when asked.  When a receiver wants our data in one of the above
   * representations, we'll get a call to  the NSPasteboardItemDataProvider protocol method –pasteboard:item:provideDataForType:. */
  [pbItem setDataProvider:self forTypes:[NSArray arrayWithObjects:NSPasteboardTypeString, nil]];

  //create a new NSDraggingItem with our pasteboard item.
  NSDraggingItem *dragItem = [[NSDraggingItem alloc] initWithPasteboardWriter:pbItem];

  /* The coordinates of the dragging frame are relative to our view.  Setting them to our view's bounds will cause the drag image
   * to be the same size as our view.  Alternatively, you can set the draggingFrame to an NSRect that is the size of the image in
   * the view but this can cause the dragged image to not line up with the mouse if the actual image is smaller than the size of the
   * our view. */
  NSRect draggingRect = self.bounds;

  /* While our dragging item is represented by an image, this image can be made up of multiple images which
   * are automatically composited together in painting order.  However, since we are only dragging a single
   * item composed of a single image, we can use the convince method below. For a more complex example
   * please see the MultiPhotoFrame sample. */
  NSImage* image = [[NSImage alloc] initWithData:[self dataWithPDFInsideRect:[self bounds]]];
  [dragItem setDraggingFrame:draggingRect contents:image];

  //create a dragging session with our drag item and ourself as the source.
  NSDraggingSession *draggingSession = [self beginDraggingSessionWithItems:[NSArray arrayWithObject:dragItem] event:_mouseDownEvent source:self];
  draggingSession.animatesToStartingPositionsOnCancelOrFail = NO;

  draggingSession.draggingFormation = NSDraggingFormationNone;
}

@end
