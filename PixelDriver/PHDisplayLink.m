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

#import "PHSystemTick.h"
#import "PHFMODRecorder.h"
#import "PHAnimationDriver.h"
#import "PHDriver.h"
#import "PHSystem.h"
#import "AppDelegate.h"
#import "Utilities.h"

NSString* const PHDisplayLinkFiredNotification = @"PHDisplayLinkFiredNotification";
NSString* const PHDisplayLinkFiredDriverKey = @"PHDisplayLinkFiredDriverKey";
NSString* const PHDisplayLinkFiredSystemTickKey = @"PHDisplayLinkFiredSystemTickKey";

static CVReturn displayLinkCallback(CVDisplayLinkRef displayLink,
                                    const CVTimeStamp* now,
                                    const CVTimeStamp* outputTime,
                                    CVOptionFlags flagsIn,
                                    CVOptionFlags* flagsOut,
                                    void* displayLinkContext) {
  @autoreleasepool {
    PHDisplayLink* displayLink = (__bridge PHDisplayLink *)(displayLinkContext);
    NSArray* motes = [PHApp() allMotes];
    NSInteger numberOfTimesUser1Pressed = PHSys().numberOfTimesUserButton1Pressed;
    NSInteger numberOfTimesUser2Pressed = PHSys().numberOfTimesUserButton2Pressed;
    NSInteger isUserButton1Pressed = PHSys().isUserButton1Pressed;
    NSInteger isUserButton2Pressed = PHSys().isUserButton2Pressed;
    [displayLink.animationDriver updateWithAudioRecorder:PHApp().audioRecorder
                                                   motes:motes
                                       didTapUserButton1:numberOfTimesUser1Pressed > 0
                                       didTapUserButton2:numberOfTimesUser2Pressed > 0
                                    isUserButton1Pressed:isUserButton1Pressed
                                    isUserButton2Pressed:isUserButton2Pressed
                                                    gifs:PHApp().gifs];

    NSMutableDictionary* userInfo = [@{
      PHDisplayLinkFiredDriverKey : displayLink.animationDriver
    } mutableCopy];

    PHSystemTick* tick = [PHSys() tick];
    if (nil != tick) {
      [userInfo setObject:tick forKey:PHDisplayLinkFiredSystemTickKey];
      [PHApp().driver queueContext:tick.wallContextRef];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:PHDisplayLinkFiredNotification
                                                        object:nil
                                                      userInfo:userInfo];
    [PHApp() didTick];
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
    _animationDriver = [[PHAnimationDriver alloc] init];

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
