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

#import <Foundation/Foundation.h>
#import "PHMIDIHardware.h"

typedef enum {
  PHDJ2GOSliderLeft,
  PHDJ2GOSliderRight,
  PHDJ2GOSliderMid,

  PHDJ2GOSliderCount,
  PHDJ2GOSliderUnknown,
} PHDJ2GOSlider;

typedef enum {
  PHDJ2GOVolumeA,
  PHDJ2GOVolumeB,
  PHDJ2GOVolumeMaster,
  PHDJ2GOVolumeHeadphones,

  PHDJ2GOVolumeCount,
  PHDJ2GOVolumeUnknown,
} PHDJ2GOVolume;

typedef enum {
  PHDJ2GOKnobBrowse,
  PHDJ2GOKnobLeft,
  PHDJ2GOKnobRight,

  PHDJ2GOKnobCount,
  PHDJ2GOKnobUnknown,
} PHDJ2GOKnob;

typedef enum {
  PHDJ2GOButtonLeftSync,
  PHDJ2GOButtonLeftHeadphones,
  PHDJ2GOButtonLeftCue,
  PHDJ2GOButtonLeftPlayPause,

  PHDJ2GOButtonRightSync,
  PHDJ2GOButtonRightHeadphones,
  PHDJ2GOButtonRightCue,
  PHDJ2GOButtonRightPlayPause,

  PHDJ2GOButtonLEDCount,

  PHDJ2GOButtonLeftPitchBendNeg = PHDJ2GOButtonLEDCount,
  PHDJ2GOButtonLeftPitchBendPos,

  PHDJ2GOButtonRightPitchBendNeg,
  PHDJ2GOButtonRightPitchBendPos,

  PHDJ2GOButtonLoadA,
  PHDJ2GOButtonLoadB,
  PHDJ2GOButtonBack,
  PHDJ2GOButtonEnter,

  PHDJ2GOButtonCount,
  PHDJ2GOButtonUnknown,
} PHDJ2GOButton;

typedef enum {
  PHDJ2GODirectionCw,
  PHDJ2GODirectionCcw,

  PHDJ2GODirectionCount,
  PHDJ2GODirectionUnknown,
} PHDJ2GODirection;

@protocol PHDJ2GODeviceDelegate;

@interface PHDJ2GODevice : PHMIDIHardware
@property (nonatomic, weak) id<PHDJ2GODeviceDelegate> delegate;

- (void)setButton:(PHDJ2GOButton)button ledStateEnabled:(BOOL)enabled;

@end

@protocol PHDJ2GODeviceDelegate <NSObject>

- (void)slider:(PHDJ2GOSlider)slider didChangeValue:(CGFloat)value;
- (void)volume:(PHDJ2GOVolume)volume didChangeValue:(CGFloat)value;
- (void)knob:(PHDJ2GOKnob)knob didRotate:(PHDJ2GODirection)direction;
- (void)buttonWasPressed:(PHDJ2GOButton)button;
- (void)buttonWasReleased:(PHDJ2GOButton)button;

@end
