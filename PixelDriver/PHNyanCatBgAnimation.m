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

#import "PHNyanCatBgAnimation.h"

#define NHISTOGRAMS 6
#define TICKEVERY 6
#define TICKMULTIPLIER 3 // how much faster do rainbows run than oscillate?

@implementation PHNyanCatBgAnimation {
    CGFloat _histograms[48*NHISTOGRAMS];
    
    NSInteger _ticks;
}

- (id)init {
    if ((self = [super init])) {
        _ticks = 0;
        
        memset(_histograms, 0, sizeof(CGFloat) * 48 * NHISTOGRAMS);
    }
    return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
    if (self.driver.unifiedSpectrum) {
        NSInteger tailHeight = kWallHeight / 13;
        
        NSColor* nyanRed = [NSColor colorWithDeviceRed:1 green:0 blue:0 alpha:1];
        NSColor* nyanOrange = [NSColor colorWithDeviceRed:1 green:0.6 blue:0 alpha:1];
        NSColor* nyanYellow = [NSColor colorWithDeviceRed:1 green:1 blue:0 alpha:1];
        NSColor* nyanGreen = [NSColor colorWithDeviceRed:0.2 green:1 blue:0 alpha:1];
        NSColor* nyanBlue = [NSColor colorWithDeviceRed:0 green:0.6 blue:1 alpha:1];
        NSColor* nyanPurple = [NSColor colorWithDeviceRed:0.4 green:0.2 blue:1 alpha:1];
        
        NSColor* color = nil;
        CGFloat amplitude = 0;
    
        for (NSInteger ix = 0; ix < NHISTOGRAMS; ++ix) {
            if (ix == 0) {
                color = nyanRed;
                amplitude = self.bassDegrader.value;
            } else if (ix == 1) {
                color = nyanOrange;
                amplitude = self.hihatDegrader.value;
            } else if (ix == 2) {
                color = nyanYellow;
                amplitude = self.vocalDegrader.value;
            } else if (ix == 3) {
                color = nyanGreen;
                amplitude = self.snareDegrader.value;
            } else if (ix == 4) {
                color = nyanBlue;
                amplitude = self.bassDegrader.value;
            } else if (ix == 5) {
                color = nyanPurple;
                amplitude = self.hihatDegrader.value;
            }
            
            // Shift all values back.
            for (NSInteger col = 0; col < kWallWidth - 1; ++col) {
                _histograms[ix * 48 + col] = _histograms[ix * 48 + col + 1];
            }
            _histograms[ix * 48 + 47] = amplitude;
            
            for (NSInteger col = kWallWidth / 2; col < kWallWidth; ++col) {
                
                NSInteger offset = (((col + (_ticks / TICKMULTIPLIER)) % (TICKEVERY * 2)) > TICKEVERY) ? 1 : 0;
                CGFloat val = _histograms[col + ix * 48] * 0.8 + 0.2;
                CGContextSetFillColorWithColor(cx, [color colorWithAlphaComponent: val].CGColor);
                CGRect line = CGRectMake(col - (kWallWidth - 18), tailHeight * ix + 11 + offset, 1, tailHeight);
                CGContextFillRect(cx, line);
            }
        };
        
        _ticks++;
        _ticks = _ticks % (TICKEVERY * TICKMULTIPLIER * 2);
    }
}

@end
