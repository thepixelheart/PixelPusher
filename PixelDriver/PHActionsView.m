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

#import "PHActionsView.h"

#import "PHButton.h"
#import "AppDelegate.h"
#import "PHSystem.h"

@interface PHActionsView() <PHButtonDelegate>
@end

@implementation PHActionsView {
  NSMutableArray* _buttons;
}

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    _buttons = [NSMutableArray array];

    [self addButtonWithImage:[NSImage imageNamed:@"pixelheart"] tag:PHSystemButtonPixelHeart];
    [self addButtonWithImage:[NSImage imageNamed:@"camera"] tag:PHSystemButtonScreenshot];
    [self addButtonWithImage:[NSImage imageNamed:@"camera_record"] tag:PHSystemButtonRecord];
    [self addButtonWithImage:[NSImage imageNamed:@"strobe"] tag:PHSystemButtonStrobe];
    [self addButtonWithImage:[NSImage imageNamed:@"bpm"] tag:PHSystemButtonTapBPM];
    [self addButtonWithImage:[NSImage imageNamed:@"nobpm"] tag:PHSystemButtonClearBPM];
  }
  return self;
}

- (void)layout {
  [super layout];

  CGSize boundsSize = self.contentView.bounds.size;
  CGSize buttonSize = CGSizeMake(floor(boundsSize.width / 4), floor(boundsSize.width / 4));
  NSInteger ix = 0;
  for (PHButton* button in _buttons) {
    CGRect frame = CGRectMake((ix % 4) * buttonSize.width, (ix / 4) * buttonSize.height, buttonSize.width, buttonSize.height);
    if (ix == 3 && CGRectGetMaxX(frame) != boundsSize.width) {
      // Rounding errors
      frame.size.width += boundsSize.width - CGRectGetMaxX(frame);
    }
    button.frame = frame;
    ++ix;
  }
}

- (void)addButtonWithImage:(NSImage *)image tag:(NSInteger)tag {
  PHButton* button = [[PHButton alloc] init];
  button.delegate = self;
  button.tag = tag;
  [button setImage:image];
  [button setTitle:@""];
  [self.contentView addSubview:button];
  [_buttons addObject:button];
}

#pragma mark - PHButtonDelegate

- (void)didPressDownButton:(PHButton *)button {
  [PHSys() didPressButton:(PHSystemControlIdentifier)button.tag];
}

- (void)didReleaseButton:(PHButton *)button {
  [PHSys() didReleaseButton:(PHSystemControlIdentifier)button.tag];
}

@end
