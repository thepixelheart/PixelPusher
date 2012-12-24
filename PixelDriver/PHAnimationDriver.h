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

@interface PHAnimationDriver : NSObject

// Raw values
@property (nonatomic, readonly) float* spectrum;
@property (nonatomic, readonly) NSInteger numberOfSpectrumValues;

// The number of Hz represented in each index of the spectrum.
// Let's say this is 10Hz. Then spectrum[0] will represent the frequency of the
// sound between 0 and 10Hz. spectrum[1] will be 10Hz and 20Hz, and so forth.
// This can be used to calculate an average over a specific Hz range in the
// spectrum and is what the amplitude values below use.
- (float)hzPerSpectrumValue;

// Processed values
// Each of these values is from 0..1, with 1 being peak amplitude.
// View the .m file to see which Hz is being averaged out to calculate these
// amplitudes.
@property (nonatomic, readonly) CGFloat subBassAmplitude;
@property (nonatomic, readonly) CGFloat hihatAmplitude;
@property (nonatomic, readonly) CGFloat vocalAmplitude;
@property (nonatomic, readonly) CGFloat snareAmplitude;

@end

@interface PHAnimationDriver()

- (void)setSpectrum:(float *)spectrum numberOfValues:(NSInteger)numberOfValues;

@end
