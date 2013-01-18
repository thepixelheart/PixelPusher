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

#import "PHPlaybackControlsView.h"

#import "PHSlider.h"
#import "AppDelegate.h"
#import "PHSystem.h"

static const CGFloat kSliderWidth = 100;
static const CGFloat kSliderHeight = 44;

const CGFloat PHPlaybackControlsWidth = kSliderWidth + 100;

@interface PHButton : NSButton
@end

@implementation PHButton
@end

@implementation PHPlaybackControlsView {
  NSSlider* _faderSlider;
  
  PHButton* _loadLeftButton;
  PHButton* _loadRightButton;
  
}

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    _faderSlider = [[PHSlider alloc] init];
    _faderSlider.numberOfTickMarks = 11;
    _faderSlider.minValue = 0;
    _faderSlider.maxValue = 1;
    [_faderSlider setContinuous:YES];
    [self.contentView addSubview:_faderSlider];

    _faderSlider.target = self;
    _faderSlider.action = @selector(faderSliderDidChange:);

    _loadLeftButton = [[PHButton alloc] init];
    [_loadLeftButton setTitle:@"Load"];
    _loadLeftButton.target = self;
    _loadLeftButton.action = @selector(didTapLeftLoadButton:);
    [self.contentView addSubview:_loadLeftButton];

    _loadRightButton = [[PHButton alloc] init];
    [_loadRightButton setTitle:@"Load"];
    _loadRightButton.target = self;
    _loadRightButton.action = @selector(didTapRightLoadButton:);
    [self.contentView addSubview:_loadRightButton];
  }
  return self;
}

- (void)layout {
  [super layout];

  CGSize boundsSize = self.contentView.bounds.size;
  _faderSlider.frame = CGRectMake(floor((boundsSize.width - kSliderWidth) / 2),
                                  floor((boundsSize.height - kSliderHeight) / 2),
                                  kSliderWidth, kSliderHeight);

  [_loadLeftButton sizeToFit];

  CGFloat leftWidth = CGRectGetMinX(_faderSlider.frame);
  _loadLeftButton.frame = CGRectMake(floor((leftWidth - _loadLeftButton.frame.size.width) / 2),
                                     floor((boundsSize.height - _loadLeftButton.frame.size.height) / 2),
                                     _loadLeftButton.frame.size.width,
                                     _loadLeftButton.frame.size.height);

  [_loadRightButton sizeToFit];

  CGFloat rightWidth = boundsSize.width - CGRectGetMaxX(_faderSlider.frame);
  _loadRightButton.frame = CGRectMake(CGRectGetMaxX(_faderSlider.frame)
                                      + floor((rightWidth - _loadRightButton.frame.size.width) / 2),
                                      floor((boundsSize.height - _loadRightButton.frame.size.height) / 2),
                                      _loadRightButton.frame.size.width,
                                      _loadRightButton.frame.size.height);
}

- (void)faderSliderDidChange:(NSSlider *)slider {
  [PHSys() setFade:slider.floatValue];
}

#pragma mark - Actions

- (void)didTapLeftLoadButton:(NSButton *)button {
  [_delegate didTapLoadLeftButton];
}

- (void)didTapRightLoadButton:(NSButton *)button {
  [_delegate didTapLoadRightButton];
}

@end
