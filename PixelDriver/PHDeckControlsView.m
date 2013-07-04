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
#import "PHSystem.h"
#import "AppDelegate.h"
#import "PHHardwareState.h"

@implementation PHDeckControlsView {
  PHCircularSlider* _speedSlider;
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
  }
  return self;
}

- (void)layout {
  [super layout];

  [_speedSlider sizeToFit];
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

@end
