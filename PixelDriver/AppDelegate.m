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

#import "AppDelegate.h"

#import "PHDriver.h"
#import "PHFMODRecorder.h"
#import "PHUSBNotifier.h"
#import "PHWallView.h"

AppDelegate *PHApp() {
  return (AppDelegate *)[NSApplication sharedApplication].delegate;
}

@implementation AppDelegate {
  PHUSBNotifier* _usbNotifier;
}

@synthesize audioRecorder = _audioRecorder;

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
  [self.window setAcceptsMouseMovedEvents:YES];
  [self.window setMovableByWindowBackground:YES];

  NSRect frame = self.window.frame;

  CGFloat midX = NSMidX(frame);
  CGFloat midY = NSMidY(frame);

  frame.size.width = kWallWidth * kPixelSize + (kWallWidth + 1) * kPixelBorderSize;
  frame.size.height = kWallHeight * kPixelSize + (kWallHeight + 1) * kPixelBorderSize;
  [self.window setMaxSize:frame.size];
  [self.window setMinSize:frame.size];

  [self.window setFrame:NSMakeRect(floorf(midX - frame.size.width * 0.5f),
                                   floorf(midY - frame.size.height * 0.5f),
                                   frame.size.width,
                                   frame.size.height)
                display:YES];

  _driver = [[PHDriver alloc] init];
  _usbNotifier = [[PHUSBNotifier alloc] init];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [self.window performSelector:@selector(makeKeyAndOrderFront:) withObject:self afterDelay:0.5];
  [self.window center];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
  return YES;
}

- (PHFMODRecorder *)audioRecorder {
  if (nil == _audioRecorder) {
    _audioRecorder = [[PHFMODRecorder alloc] init];
  }
  return _audioRecorder;
}

@end
