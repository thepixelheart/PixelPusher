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

#import "PHSystemTick.h"

#import "PHDriver.h"
#import "PHSystem+Protected.h"
#import "PHTransition.h"

@implementation PHSystemTick {
  CGFloat _masterFade;
}

@synthesize leftContextRef = _leftContextRef;
@synthesize rightContextRef = _rightContextRef;
@synthesize previewContextRef = _previewContextRef;
@synthesize wallContextRef = _wallContextRef;

- (void)dealloc {
  if (nil != _leftContextRef) {
    CGContextRelease(_leftContextRef);
  }
  if (nil != _rightContextRef) {
    CGContextRelease(_rightContextRef);
  }
  if (nil != _previewContextRef) {
    CGContextRelease(_previewContextRef);
  }
  if (nil != _wallContextRef) {
    CGContextRelease(_wallContextRef);
  }
  if (nil != _editingCompositeContextRef) {
    CGContextRelease(_editingCompositeContextRef);
  }
}

- (id)initWithMasterFade:(CGFloat)masterFade {
  if ((self = [super init])) {
    _masterFade = masterFade;
  }
  return self;
}

- (void)setLeftContextRef:(CGContextRef)leftContextRef {
  if (_leftContextRef == leftContextRef) {
    return;
  }
  if (nil != _leftContextRef) {
    CGContextRelease(_leftContextRef);
  }
  _leftContextRef = CGContextRetain(leftContextRef);
}

- (void)setRightContextRef:(CGContextRef)rightContextRef {
  if (_rightContextRef == rightContextRef) {
    return;
  }
  if (nil != _rightContextRef) {
    CGContextRelease(_rightContextRef);
  }
  _rightContextRef = CGContextRetain(rightContextRef);
}

- (void)setPreviewContextRef:(CGContextRef)previewContextRef {
  if (_previewContextRef == previewContextRef) {
    return;
  }
  if (nil != _previewContextRef) {
    CGContextRelease(_previewContextRef);
  }
  _previewContextRef = CGContextRetain(previewContextRef);
}

- (void)setWallContextRef:(CGContextRef)wallContextRef {
  if (_wallContextRef == wallContextRef) {
    return;
  }
  if (nil != _wallContextRef) {
    CGContextRelease(_wallContextRef);
  }
  _wallContextRef = CGContextRetain(wallContextRef);
}

- (void)setEditingCompositeContextRef:(CGContextRef)editingCompositeContextRef {
  if (_editingCompositeContextRef == editingCompositeContextRef) {
    return;
  }
  if (nil != _editingCompositeContextRef) {
    CGContextRelease(_editingCompositeContextRef);
  }
  _editingCompositeContextRef = CGContextRetain(editingCompositeContextRef);
}

- (void)updateWallContextWithTransition:(PHTransition *)transition t:(CGFloat)t flip:(BOOL)flip {
  CGContextRef wallPrepContext = [PHSystem createWallContext];

  CGSize wallSize = CGSizeMake(kWallWidth, kWallHeight);
  [transition renderBitmapInContext:wallPrepContext
                               size:wallSize
                        leftContext:flip ? _rightContextRef : _leftContextRef
                       rightContext:flip ? _leftContextRef : _rightContextRef
                                  t:flip ? (1 - t) : t];

  CGContextRef wallContext = [PHSystem createWallContext];
  CGContextSaveGState(wallContext);
  {
    CGContextSetAlpha(wallContext, _masterFade);
    CGImageRef prepImageRef = CGBitmapContextCreateImage(wallPrepContext);
    CGContextDrawImage(wallContext, CGRectMake(0, 0, kWallWidth, kWallHeight), prepImageRef);
    CGImageRelease(prepImageRef);
    CGContextRelease(wallPrepContext);
  }
  CGContextRestoreGState(wallContext);

  self.wallContextRef = wallContext;

  CGContextRelease(wallContext);
}

@end
