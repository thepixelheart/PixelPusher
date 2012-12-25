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

@interface PHFMODRecorder : NSObject

- (BOOL)isListening;
- (void)toggleListening;

@property (nonatomic, copy, readonly) NSArray* playbackDriverNames;
@property (nonatomic, copy, readonly) NSArray* recordDriverNames;

@property (nonatomic, assign) int playbackDriverIndex;
@property (nonatomic, assign) int recordDriverIndex;

@property (nonatomic, assign) float volume;

- (void)getSpectrumLeft:(float **)left right:(float **)right unified:(float **)unified;
- (NSInteger)numberOfSpectrumValues;

- (void)getHighResSpectrumLeft:(float **)left right:(float **)right unified:(float **)unified;
- (NSInteger)numberOfHighResSpectrumValues;

- (void)getWaveLeft:(float **)left right:(float **)right unified:(float **)unified;
- (NSInteger)numberOfWaveDataValues;

@end
