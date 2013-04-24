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

#import "PHMote.h"

// Private APIs
@interface PHMote()

- (id)initWithName:(NSString *)name identifier:(NSString *)identifier stream:(NSStream *)stream;

@property (nonatomic, readonly) NSStream* stream;

- (void)addControllerState:(PHMoteState *)state;
- (void)tick;

@property (nonatomic, strong) PHMoteState* lastState;
@property (nonatomic, assign) BOOL streaming;

@end
