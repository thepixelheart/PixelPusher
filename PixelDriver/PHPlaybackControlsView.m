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

static const CGFloat kSliderWidth = 100;
static const CGFloat kSliderHeight = 44;

const CGFloat PHPlaybackControlsWidth = kSliderWidth + 20;

@implementation PHPlaybackControlsView {
  NSSlider* _faderSlider;
}

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    _faderSlider = [[PHSlider alloc] init];
    _faderSlider.numberOfTickMarks = 11;
    _faderSlider.minValue = 0;
    _faderSlider.maxValue = 100;
    [_faderSlider setContinuous:YES];
    [self.contentView addSubview:_faderSlider];

    _faderSlider.target = self;
    _faderSlider.action = @selector(faderSliderDidChange:);
  }
  return self;
}

- (void)layout {
  [super layout];

  CGSize boundsSize = self.contentView.bounds.size;
  _faderSlider.frame = CGRectMake(floor((boundsSize.width - kSliderWidth) / 2),
                                  floor((boundsSize.height - kSliderHeight) / 2),
                                  kSliderWidth, kSliderHeight);
}

- (void)faderSliderDidChange:(NSSlider *)slider {
  NSLog(@"%f", slider.floatValue);
}

@end
