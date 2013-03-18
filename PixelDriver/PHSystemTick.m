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

@implementation PHSystemTick

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

- (void)updateWallContextWithTransition:(PHTransition *)transition t:(CGFloat)t {
  CGContextRef wallContext = [PHSystem createWallContext];

  CGSize wallSize = CGSizeMake(kWallWidth, kWallHeight);
  [transition renderBitmapInContext:wallContext
                               size:wallSize
                        leftContext:_leftContextRef
                       rightContext:_rightContextRef
                                  t:t];

  self.wallContextRef = wallContext;

  CGContextRelease(wallContext);
}

@end
