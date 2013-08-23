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

#import "PHAnimationList.h"

static NSString* kNameKey = @"kNameKey";
static NSString* kGuidsKey = @"kGuidsKey";

@implementation PHAnimationList

- (id)init {
  if ((self = [super init])) {
    _name = @"<New List>";
    _guids = [NSMutableSet set];
  }
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  PHAnimationList* animation = [[self.class allocWithZone:zone] init];
  animation->_name = [_name copy];
  animation->_guids = [_guids mutableCopy];
  return animation;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  if (nil != _name) {
    [coder encodeObject:_name forKey:kNameKey];
  }
  if (nil != _guids) {
    [coder encodeObject:_guids forKey:kGuidsKey];
  }
}

- (id)initWithCoder:(NSCoder *)decoder {
  if ((self = [self init])) {
    _name = [[decoder decodeObjectForKey:kNameKey] copy];
    _guids = [[decoder decodeObjectForKey:kGuidsKey] mutableCopy];
  }
  return self;
}

@end
