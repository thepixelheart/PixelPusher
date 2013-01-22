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

#import "PHMIDIDriver.h"

#import "PHMIDIDevice.h"

@interface PHMIDIDriver() <PHMIDIClientDelegate>
@end

@implementation PHMIDIDriver {
  PHMIDIClient* _client;
  NSMutableDictionary* _devices;
}

- (id)init {
  if ((self = [super init])) {
    _client = [[PHMIDIClient alloc] init];
    _client.delegate = self;
  }
  return self;
}

- (PHMIDIDevice *)deviceWithUniqueID:(NSString *)uniqueID {
  return [_devices objectForKey:uniqueID];
}

#pragma mark - PHMIDIClientDelegate

- (void)midiConnectionsDidChange {
  _devices = [NSMutableDictionary dictionary];

  ItemCount numberOfSources = MIDIGetNumberOfSources();
  for (ItemCount ix = 0; ix < numberOfSources; ++ix)  {
    MIDIEndpointRef endpoint = MIDIGetSource(ix);

    PHMIDIDevice* device = [[PHMIDIDevice alloc] initWithClient:_client sourceEndpointRef:endpoint];
    [_devices setObject:device forKey:[device name]];
  }

  ItemCount numberOfDestinations = MIDIGetNumberOfDestinations();
  for (ItemCount ix = 0; ix < numberOfDestinations; ++ix)  {
    MIDIEndpointRef endpoint = MIDIGetDestination(ix);

    NSString* uniqueId = [PHMIDIDevice nameFromEndpointRef:endpoint];
    PHMIDIDevice* device = [_devices objectForKey:uniqueId];
    if (nil != device) {
      device.destinationEndpointRef = endpoint;
    }
  }
}

@end
