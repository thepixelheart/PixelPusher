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

- (void)awakeFromNib {
  [super awakeFromNib];

  [self driverConnectionDidChange];

  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(driverConnectionDidChange)
             name:PHDriverConnectionStateDidChangeNotification
           object:nil];
}

- (void)drawRect:(NSRect)dirtyRect {
  [super drawRect:dirtyRect];

  CGContextRef cx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
  [[NSColor colorWithDeviceRed:255 green:0 blue:0 alpha:1] set];
  CGContextFillRect(cx, self.bounds);
}

- (void)driverConnectionDidChange {
  if (PHApp().driver.isConnected) {
    NSLog(@"Driver is attached");
  } else {
    NSLog(@"Driver is detached");
  }
}

@end
