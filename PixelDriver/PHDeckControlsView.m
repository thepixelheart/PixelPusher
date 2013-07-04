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

#import "PHDeckControlsView.h"

#import "PHCircularSlider.h"
#import "PHButton.h"
#import "PHSystem.h"
#import "AppDelegate.h"
#import "PHHardwareState.h"

@interface PHDeckControlsView () <PHButtonDelegate>
@end

@implementation PHDeckControlsView {
  PHCircularSlider* _speedSlider;

  PHButton* _action1;
  PHButton* _action2;
}

- (id)initWithSystemTagOffset:(NSInteger)tagOffset {
  if ((self = [super initWithFrame:NSZeroRect])) {
    _speedSlider = [[PHCircularSlider alloc] init];
    _speedSlider.circularSliderType = PHCircularSliderType_Volume;
    _speedSlider.tag = PHSystemDeckSpeed + tagOffset;
    _speedSlider.target = self;
    _speedSlider.action = @selector(sliderDidChange:);
    [_speedSlider setToolTip:@"Speed"];
    [self.contentView addSubview:_speedSlider];

    _action1 = [[PHButton alloc] init];
    _action1.tag = PHSystemDeckAction1 + tagOffset;
    _action1.delegate = self;
    [_action1 setTitle:@"1"];
    [self.contentView addSubview:_action1];

    _action2 = [[PHButton alloc] init];
    _action2.tag = PHSystemDeckAction2 + tagOffset;
    _action2.delegate = self;
    [_action2 setTitle:@"2"];
    [self.contentView addSubview:_action2];
  }
  return self;
}

- (void)layout {
  [super layout];

  [_speedSlider sizeToFit];
  [_action1 sizeToFit];
  [_action2 sizeToFit];

  _action1.frame = CGRectMake(_speedSlider.frame.size.width + 5, 0, _action1.frame.size.width, _action1.frame.size.height);
  _action2.frame = CGRectMake(CGRectGetMaxX(_action1.frame) + 5, 0, _action2.frame.size.width, _action2.frame.size.height);
}

#pragma mark - PHCircularSlider

- (void)sliderDidChange:(PHCircularSlider *)slider {
  if (slider.circularSliderType == PHCircularSliderType_Volume) {
    [PHSys() didChangeVolumeControl:(PHSystemControlIdentifier)slider.tag volume:slider.volume];
  }
}

#pragma mark - Public Methods

- (void)updateWithHardware:(PHHardwareState *)hardware {
  _speedSlider.volume = hardware.volume;
}

#pragma mark - PHButtonDelegate

- (void)didPressDownButton:(PHButton *)button {
  [PHSys() didPressButton:(PHSystemControlIdentifier)button.tag];
}

- (void)didReleaseButton:(PHButton *)button {
  [PHSys() didReleaseButton:(PHSystemControlIdentifier)button.tag];
}

@end
