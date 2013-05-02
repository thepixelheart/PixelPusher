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

#import "PHApplication.h"

#import "PHSystem.h"
#import "AppDelegate.h"

@implementation PHApplication

- (void)sendEvent:(NSEvent *)theEvent {
  BOOL didHandle = NO;

  if (PHSys().fullscreenMode) {
    NSMutableDictionary* keyMappings = [@{
                                        @"f": @(PHSystemButtonFullScreen),
                                        } mutableCopy];

    if ((theEvent.type ==
         NSKeyDown || theEvent.type == NSKeyUp)
        && (nil != keyMappings[theEvent.charactersIgnoringModifiers]
            || nil != keyMappings[[NSString stringWithFormat:@"%d", theEvent.keyCode]])) {
          id value = keyMappings[theEvent.charactersIgnoringModifiers];
          if (nil == value) {
            value = keyMappings[[NSString stringWithFormat:@"%d", theEvent.keyCode]];
          }
          PHSystemControlIdentifier button = [value intValue];
          if (theEvent.type == NSKeyDown) {
            [PHSys() didPressButton:button];
          } else {
            [PHSys() didReleaseButton:button];
          }
          
          didHandle = YES;
        }
  }
  
  if (!didHandle) {
    [super sendEvent:theEvent];
  }
}

@end
