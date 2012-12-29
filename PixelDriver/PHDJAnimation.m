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

#import "PHDJAnimation.h"

@implementation PHDJAnimation {
  PHSpritesheet* _jeffSpritesheet;
  PHSpritesheet* _antonSpritesheet;
  PHSpritesheet* _tableSpritesheet;
  PHSpritesheet* _recordSpritesheet;
  PHSpritesheet* _launchpadSpritesheet;
}

- (id)init {
  if ((self = [super init])) {
    _jeffSpritesheet = [[PHSpritesheet alloc] initWithName:@"jeff" spriteSize:CGSizeMake(16, 24)];
    _antonSpritesheet = [[PHSpritesheet alloc] initWithName:@"anton" spriteSize:CGSizeMake(16, 24)];
    _tableSpritesheet = [[PHSpritesheet alloc] initWithName:@"table" spriteSize:CGSizeMake(48, 20)];
    _recordSpritesheet = [[PHSpritesheet alloc] initWithName:@"record" spriteSize:CGSizeMake(9, 7)];
    _launchpadSpritesheet = [[PHSpritesheet alloc] initWithName:@"launchpad" spriteSize:CGSizeMake(10, 7)];
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  
}

@end
