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
#import "PHButton.h"

static const CGFloat kSliderWidth = 100;
static const CGFloat kSliderHeight = 33;

const CGFloat PHPlaybackControlsWidth = kSliderWidth + 100;

@interface PHPlaybackControlsView() <PHButtonDelegate>
@end

@implementation PHPlaybackControlsView {
  NSSlider* _faderSlider;
  
  PHButton* _loadLeftButton;
  PHButton* _loadRightButton;

  PHButton* _fadeLeftButton;
  PHButton* _fadeRightButton;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    _faderSlider = [[PHSlider alloc] init];
    _faderSlider.numberOfTickMarks = 11;
    _faderSlider.minValue = 0;
    _faderSlider.maxValue = 1;
    _faderSlider.tag = PHSystemSliderFader;
    [_faderSlider setContinuous:YES];
    [self.contentView addSubview:_faderSlider];

    _faderSlider.target = self;
    _faderSlider.action = @selector(faderSliderDidChange:);

    _loadLeftButton = [[PHButton alloc] init];
    _loadLeftButton.tag = PHSystemButtonLoadLeft;
    _loadLeftButton.delegate = self;
    [_loadLeftButton setTitle:@"Load"];
    [self.contentView addSubview:_loadLeftButton];

    _loadRightButton = [[PHButton alloc] init];
    _loadRightButton.tag = PHSystemButtonLoadRight;
    _loadRightButton.delegate = self;
    [_loadRightButton setTitle:@"Load"];
    [self.contentView addSubview:_loadRightButton];

    _fadeLeftButton = [[PHButton alloc] init];
    _fadeLeftButton.tag = PHSystemButtonSwapFaderPositions;
    _fadeLeftButton.delegate = self;
    [self.contentView addSubview:_fadeLeftButton];

    _fadeRightButton = [[PHButton alloc] init];
    _fadeRightButton.tag = PHSystemButtonSwapFaderPositions;
    _fadeRightButton.delegate = self;
    [self.contentView addSubview:_fadeRightButton];

    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(faderDidSwapNotification:) name:PHSystemFaderDidSwapNotification object:nil];
    [self updateFaderButtons];
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
  [_loadRightButton sizeToFit];
  [_fadeLeftButton sizeToFit];
  [_fadeRightButton sizeToFit];

  CGFloat width = boundsSize.width / 2 - PHPlaybackControlsWidth / 2;
  _loadLeftButton.frame = CGRectMake(floor((width - _loadLeftButton.frame.size.width) / 2),
                                     floor((boundsSize.height - _loadLeftButton.frame.size.height) / 2),
                                     _loadLeftButton.frame.size.width,
                                     _loadLeftButton.frame.size.height);

  _loadRightButton.frame = CGRectMake(boundsSize.width / 2 + PHPlaybackControlsWidth / 2
                                      + floor((width - _loadRightButton.frame.size.width) / 2),
                                      floor((boundsSize.height - _loadRightButton.frame.size.height) / 2),
                                      _loadRightButton.frame.size.width,
                                      _loadRightButton.frame.size.height);

  _fadeLeftButton.frame = CGRectMake(CGRectGetMinX(_faderSlider.frame) - _fadeLeftButton.frame.size.width - 10,
                                      floor((boundsSize.height - _fadeLeftButton.frame.size.height) / 2),
                                      _fadeLeftButton.frame.size.width,
                                      _fadeLeftButton.frame.size.height);

  _fadeRightButton.frame = CGRectMake(CGRectGetMaxX(_faderSlider.frame) + 10,
                                      floor((boundsSize.height - _fadeRightButton.frame.size.height) / 2),
                                      _fadeRightButton.frame.size.width,
                                      _fadeRightButton.frame.size.height);
}

- (void)faderSliderDidChange:(NSSlider *)slider {
  [PHSys() setFade:slider.floatValue];
}

- (void)updateFaderButtons {
  if (PHSys().leftAnimationIsBottom) {
    [_fadeLeftButton setTitle:@"Bottom"];
    [_fadeRightButton setTitle:@"Top"];
  } else {
    [_fadeLeftButton setTitle:@"Top"];
    [_fadeRightButton setTitle:@"Bottom"];
  }
  [_fadeLeftButton setState:NSOffState];
  [_fadeRightButton setState:NSOffState];
  [_fadeLeftButton setNeedsDisplay:YES];
  [_fadeRightButton setNeedsDisplay:YES];
  [_fadeRightButton layout];
  [self setNeedsLayout:YES];
  [self layout];
}

#pragma mark - PHButtonDelegate

- (void)didPressDownButton:(PHButton *)button {
  [PHSys() didPressButton:(PHSystemControlIdentifier)button.tag];
}

- (void)didReleaseButton:(PHButton *)button {
  [PHSys() didReleaseButton:(PHSystemControlIdentifier)button.tag];
}

#pragma mark - Notifications

- (void)faderDidSwapNotification:(NSNotification *)notification {
  [self updateFaderButtons];
}

@end
