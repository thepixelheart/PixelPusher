//
// Copyright 2012 Jeff Verkoeyen
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

#import "PHMote.h"

@class PHFMODRecorder;

// Ported from the pitch detection example in the FMOD samples.
typedef enum {
  PHPitchC0,
  PHPitchCSharp0,
  PHPitchD0,
  PHPitchDSharp0,
  PHPitchE0,
  PHPitchF0,
  PHPitchFSharp0,
  PHPitchG0,
  PHPitchGSharp0,
  PHPitchA0,
  PHPitchASharp0,
  PHPitchB0,
  PHPitchC1,
  PHPitchCSharp1,
  PHPitchD1,
  PHPitchDSharp1,
  PHPitchE1,
  PHPitchF1,
  PHPitchFSharp1,
  PHPitchG1,
  PHPitchGSharp1,
  PHPitchA1,
  PHPitchASharp1,
  PHPitchB1,
  PHPitchC2,
  PHPitchCSharp2,
  PHPitchD2,
  PHPitchDSharp2,
  PHPitchE2,
  PHPitchF2,
  PHPitchFSharp2,
  PHPitchG2,
  PHPitchGSharp2,
  PHPitchA2,
  PHPitchASharp2,
  PHPitchB2,
  PHPitchC3,
  PHPitchCSharp3,
  PHPitchD3,
  PHPitchDSharp3,
  PHPitchE3,
  PHPitchF3,
  PHPitchFSharp3,
  PHPitchG3,
  PHPitchGSharp3,
  PHPitchA3,
  PHPitchASharp3,
  PHPitchB3,
  PHPitchC4,
  PHPitchCSharp4,
  PHPitchD4,
  PHPitchDSharp4,
  PHPitchE4,
  PHPitchF4,
  PHPitchFSharp4,
  PHPitchG4,
  PHPitchGSharp4,
  PHPitchA4,
  PHPitchASharp4,
  PHPitchB4,
  PHPitchC5,
  PHPitchCSharp5,
  PHPitchD5,
  PHPitchDSharp5,
  PHPitchE5,
  PHPitchF5,
  PHPitchFSharp5,
  PHPitchG5,
  PHPitchGSharp5,
  PHPitchA5,
  PHPitchASharp5,
  PHPitchB5,
  PHPitchC6,
  PHPitchCSharp6,
  PHPitchD6,
  PHPitchDSharp6,
  PHPitchE6,
  PHPitchF6,
  PHPitchFSharp6,
  PHPitchG6,
  PHPitchGSharp6,
  PHPitchA6,
  PHPitchASharp6,
  PHPitchB6,
  PHPitchC7,
  PHPitchCSharp7,
  PHPitchD7,
  PHPitchDSharp7,
  PHPitchE7,
  PHPitchF7,
  PHPitchFSharp7,
  PHPitchG7,
  PHPitchGSharp7,
  PHPitchA7,
  PHPitchASharp7,
  PHPitchB7,
  PHPitchC8,
  PHPitchCSharp8,
  PHPitchD8,
  PHPitchDSharp8,
  PHPitchE8,
  PHPitchF8,
  PHPitchFSharp8,
  PHPitchG8,
  PHPitchGSharp8,
  PHPitchA8,
  PHPitchASharp8,
  PHPitchB8,
  PHPitchC9,
  PHPitchCSharp9,
  PHPitchD9,
  PHPitchDSharp9,
  PHPitchE9,
  PHPitchF9,
  PHPitchFSharp9,
  PHPitchG9,
  PHPitchGSharp9,
  PHPitchA9,
  PHPitchASharp9,
  PHPitchB9,

  PHPitch_Count,
  PHPitch_Unknown,
} PHPitch;

@interface PHSystemState : NSObject

// Raw values
@property (nonatomic, readonly) float* unifiedSpectrum;
@property (nonatomic, readonly) float* leftSpectrum;
@property (nonatomic, readonly) float* rightSpectrum;
@property (nonatomic, readonly) NSInteger numberOfSpectrumValues;

@property (nonatomic, readonly) float* highResUnifiedSpectrum;
@property (nonatomic, readonly) float* highResLeftSpectrum;
@property (nonatomic, readonly) float* highResRightSpectrum;
@property (nonatomic, readonly) NSInteger numberOfHighResSpectrumValues;

@property (nonatomic, readonly) float* unifiedWaveData;
@property (nonatomic, readonly) float* leftWaveData;
@property (nonatomic, readonly) float* rightWaveData;
@property (nonatomic, readonly) float* differenceWaveData;
@property (nonatomic, readonly) NSInteger numberOfWaveDataValues;

// These values scale the intensity calculated from the spectrum for their corresponding
// range. These values degrade over time and can only be reset by calling resetScales.
// The "Learn" button (top left button) on the Launchpad calls resetScales.
@property (nonatomic, readonly) CGFloat subBassScale;
@property (nonatomic, readonly) CGFloat hihatScale;
@property (nonatomic, readonly) CGFloat vocalScale;
@property (nonatomic, readonly) CGFloat snareScale;

// The number of Hz represented in each index of the spectrum.
// Let's say this is 10Hz. Then spectrum[0] will represent the frequency of the
// sound between 0 and 10Hz. spectrum[1] will be 10Hz and 20Hz, and so forth.
// This can be used to calculate an average over a specific Hz range in the
// spectrum and is what the amplitude values below use.
- (float)hzPerSpectrumValue;
- (float)hzPerHighResSpectrumValue;

// Processed values
// Each of these values is from 0..1, with 1 being peak amplitude.
// View the .m file to see which Hz is being averaged out to calculate these
// amplitudes.
@property (nonatomic, readonly) CGFloat subBassAmplitude;
@property (nonatomic, readonly) CGFloat hihatAmplitude;
@property (nonatomic, readonly) CGFloat vocalAmplitude;
@property (nonatomic, readonly) CGFloat snareAmplitude;

@property (nonatomic, readonly) PHPitch dominantPitch;
- (NSString *)nameOfPitch:(PHPitch)pitch;

// Motes
@property (nonatomic, readonly) NSArray* motes;

// Gifs
@property (nonatomic, readonly) NSArray* gifs;

// Kinect
@property (nonatomic, readonly) CGImageRef kinectColorImage;

@end

@interface PHSystemState()

- (void)updateWithAudioRecorder:(PHFMODRecorder *)audio
                          motes:(NSArray *)motes
                           gifs:(NSArray *)gifs
               kinectColorImage:(CGImageRef)kinectColorImage;

// Forcefully resets the frequency scales back to their original (slightly too high)
// values. This may be necessary when a song peaked out all of the values way too
// much.
- (void)resetScales;

@end
