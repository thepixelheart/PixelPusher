//
// Copyright 2012 Jeff Verkoeyen, Greg Marra
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

#import "PHLevelsHorizAnimation.h"

@implementation PHLevelsHorizAnimation {
    PHDegrader* _bassDegrader;
    PHDegrader* _hihatDegrader;
    PHDegrader* _vocalDegrader;
    PHDegrader* _snareDegrader;
}

- (id)init {
    if ((self = [super init])) {
        _bassDegrader = [[PHDegrader alloc] init];
        _hihatDegrader = [[PHDegrader alloc] init];
        _vocalDegrader = [[PHDegrader alloc] init];
        _snareDegrader = [[PHDegrader alloc] init];
    }
    return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
    if (self.driver.unifiedSpectrum) {
        [_bassDegrader tickWithPeak:self.driver.subBassAmplitude];
        [_hihatDegrader tickWithPeak:self.driver.hihatAmplitude];
        [_vocalDegrader tickWithPeak:self.driver.vocalAmplitude];
        [_snareDegrader tickWithPeak:self.driver.snareAmplitude];
        
        int wallQuartile = kWallHeight / 4;
        
        CGContextSetRGBFillColor(cx, 1, 0, 0, 1);
        CGContextFillRect(cx, CGRectMake(0, 0, _bassDegrader.value * size.width, wallQuartile));
        
        CGContextSetRGBFillColor(cx, 0, 1, 0, 1);
        CGContextFillRect(cx, CGRectMake(0, wallQuartile, _hihatDegrader.value * size.width, wallQuartile));
        
        CGContextSetRGBFillColor(cx, 0, 0, 1, 1);
        CGContextFillRect(cx, CGRectMake(0, 2 * wallQuartile, _vocalDegrader.value * size.width, wallQuartile));
        
        CGContextSetRGBFillColor(cx, 1, 0, 1, 1);
        CGContextFillRect(cx, CGRectMake(0, 3 * wallQuartile, _snareDegrader.value * size.width, wallQuartile));
    }
}

@end
