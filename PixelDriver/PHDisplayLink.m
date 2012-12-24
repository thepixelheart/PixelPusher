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

#import "PHDisplayLink.h"

#import "PHFMODRecorder.h"
#import "AppDelegate.h"
#import "Utilities.h"

NSString* const PHDisplayLinkFiredNotification = @"PHDisplayLinkFiredNotification";
NSString* const PHDisplayLinkFiredSpectrumKey = @"PHDisplayLinkFiredSpectrumKey";
NSString* const PHDisplayLinkFiredNumberOfSpectrumValuesKey = @"PHDisplayLinkFiredNumberOfSpectrumValuesKey";
NSString* const PHDisplayLinkFiredHighResSpectrumKey = @"PHDisplayLinkFiredHighResSpectrumKey";
NSString* const PHDisplayLinkFiredNumberOfHighResSpectrumValuesKey = @"PHDisplayLinkFiredNumberOfHighResSpectrumValuesKey";

static CVReturn displayLinkCallback(CVDisplayLinkRef displayLink,
                                    const CVTimeStamp* now,
                                    const CVTimeStamp* outputTime,
                                    CVOptionFlags flagsIn,
                                    CVOptionFlags* flagsOut,
                                    void* displayLinkContext) {
  @autoreleasepool {
    float* spectrum = [PHApp().audioRecorder spectrum];
    NSInteger numberOfSpectrumValues = [PHApp().audioRecorder numberOfSpectrumValues];
    float* highResSpectrum = [PHApp().audioRecorder highResSpectrum];
    NSInteger numberOfHighResSpectrumValues = [PHApp().audioRecorder numberOfHighResSpectrumValues];

    NSDictionary* userInfo = @{
      PHDisplayLinkFiredSpectrumKey : [NSValue valueWithPointer:spectrum],
      PHDisplayLinkFiredNumberOfSpectrumValuesKey: [NSNumber numberWithLong:numberOfSpectrumValues],
      PHDisplayLinkFiredHighResSpectrumKey : [NSValue valueWithPointer:highResSpectrum],
      PHDisplayLinkFiredNumberOfHighResSpectrumValuesKey: [NSNumber numberWithLong:numberOfHighResSpectrumValues]
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:PHDisplayLinkFiredNotification object:nil userInfo:userInfo];
    return kCVReturnSuccess;
  }
}

@implementation PHDisplayLink {
  CVDisplayLinkRef _displayLink;
}

- (void)dealloc {
  CVDisplayLinkRelease(_displayLink);
}

- (id)init {
  if ((self = [super init])) {
    if (kCVReturnSuccess != CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink)) {
      PHAlert(@"Unable to set up a timer for the animations.");
      self = nil;
      return self;
    }
    CVDisplayLinkSetOutputCallback(_displayLink, &displayLinkCallback, (__bridge void*)self);
    CVDisplayLinkStart(_displayLink);
  }
  return self;
}

@end
