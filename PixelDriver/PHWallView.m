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

#import "PHWallView.h"

#import "AppDelegate.h"
#import "PHDriver.h"

@implementation PHWallView

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    [self updateDriverConnectedState];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(updateDriverConnectedState)
               name:PHDriverConnectionStateDidChangeNotification
             object:nil];
  }
  return self;
}

- (void)drawRect:(NSRect)dirtyRect {
  [super drawRect:dirtyRect];

  CGContextRef cx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
  [[NSColor colorWithDeviceRed:255 green:0 blue:0 alpha:1] set];
  CGContextFillRect(cx, self.bounds);
}

- (void)updateDriverConnectedState {
  if (PHApp().driver.isConnected) {
    // Show a connected state.
  } else {
    // Show a disconnected state.
  }
}

@end
