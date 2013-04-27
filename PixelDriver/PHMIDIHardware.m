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

#import "PHMIDIHardware.h"
#import "PHMIDIHardware+Subclassing.h"

#import "PHMIDIDriver.h"
#import "PHMIDIDevice.h"

@interface PHMIDIHardware ()
@property (nonatomic, strong) PHMIDIDevice* device;
@end

@implementation PHMIDIHardware

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init {
  if ((self = [super init])) {
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(midiDevicesDidChangeNotification:)
               name:PHMIDIDriverDevicesDidChangeNotification object:nil];
  }
  return self;
}

+ (NSString *)hardwareName {
  return nil;
}

- (void)syncDeviceState {
  // No-op.
}

- (void)didReceiveMIDIMessages:(NSArray *)messages {
  // No-op.
}

#pragma mark - PHMIDIDriverDevicesDidChangeNotification

- (void)midiDevicesDidChangeNotification:(NSNotification *)notification {
  NSDictionary* devices = notification.userInfo[PHMIDIDevicesKey];

  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  if (nil != self.device) {
    [nc removeObserver:self name:PHMIDIDeviceDidReceiveMessagesNotification object:self.device];
  }

  self.device = devices[self.class.hardwareName];

  if (nil != self.device) {
    [nc addObserver:self selector:@selector(didReceiveMIDIMessagesNotification:) name:PHMIDIDeviceDidReceiveMessagesNotification object:self.device];

    [self syncDeviceState];
  }
}

#pragma mark - PHMIDIDeviceDidReceiveMessagesNotification

- (void)didReceiveMIDIMessagesNotification:(NSNotification *)notification {
  if ([NSThread currentThread] != [NSThread mainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self didReceiveMIDIMessagesNotification:notification];
    });
    return;
  }

  NSArray* messages = notification.userInfo[PHMIDIMessagesKey];
  [self didReceiveMIDIMessages:messages];
}

@end
