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

#import "PHDJ2GODevice.h"

#import "PHMIDIDriver.h"
#import "PHMIDIDevice.h"
#import "PHMIDIMessage+DJ2GO.h"

static NSString* const kDeviceName = @"Numark DJ2Go";
const NSInteger PHDJ2GOUnknown = -1;

@implementation PHDJ2GODevice {
  PHMIDIDevice* _device;

  CGFloat _sliders[PHDJ2GOSliderCount];
  CGFloat _volumes[PHDJ2GOVolumeCount];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init {
  if ((self = [super init])) {
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(midiDevicesDidChangeNotification:)
               name:PHMIDIDriverDevicesDidChangeNotification object:nil];

    memset(_sliders, 0, sizeof(CGFloat) * PHDJ2GOSliderCount);
    memset(_volumes, 0, sizeof(CGFloat) * PHDJ2GOVolumeCount);
  }
  return self;
}

#pragma mark - PHMIDIDriverDevicesDidChangeNotification

- (void)midiDevicesDidChangeNotification:(NSNotification *)notification {
  NSDictionary* devices = notification.userInfo[PHMIDIDevicesKey];

  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  if (nil != _device) {
    [nc removeObserver:self name:PHMIDIDeviceDidReceiveMessagesNotification object:_device];
  }

  _device = devices[kDeviceName];

  if (nil != _device) {
    [nc addObserver:self selector:@selector(didReceiveMIDIMessages:) name:PHMIDIDeviceDidReceiveMessagesNotification object:_device];
  }
}

#pragma mark - PHMIDIDeviceDidReceiveMessagesNotification

- (void)didReceiveMIDIMessages:(NSNotification *)notification {
  NSArray* messages = notification.userInfo[PHMIDIMessagesKey];
  for (PHMIDIMessage* message in messages) {
    
  }
}

@end
