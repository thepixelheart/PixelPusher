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

#import "PHFont.h"

#import "Utilities.h"

static NSImage* kFontImage = nil;

static const NSInteger kCharacterLocations[] = {
  'A','B','C','D','E','F','G','H','I',
  'J','K','L','M','N','O','P','Q','R',
  'S','T','U','V','W','X','Y','Z','1',
  '2','3','4','5','6','7','8','9','0','.',
  ':','+','-'
};
static const NSInteger kNumberOfCharacters = sizeof(kCharacterLocations) / sizeof(kCharacterLocations[0]);

// The frame of each character in the kFontImage.
static CGRect kCharacterRects[kNumberOfCharacters];

static const CGSize kStandardCharacterSize = {5,7};

// Maps any ASCII character to their index in the kCharacterLocations array.
static NSInteger kCharacterMap[256];

@implementation PHFont

+ (void)initialize {
  NSString* filename = PHFilenameForResourcePath([[@"spritesheets" stringByAppendingPathComponent:@"font"] stringByAppendingPathExtension:@"png"]);
  kFontImage = [[NSImage alloc] initWithData:[NSData dataWithContentsOfFile:filename]];

  // Map ASCII characters to the kCharacterLocations map.
  memset(kCharacterMap, 0, sizeof(kCharacterMap));
  for (NSInteger ix = 0; ix < kNumberOfCharacters; ++ix) {
    NSInteger character = kCharacterLocations[ix];
    kCharacterMap[character] = ix;
  }

  memset(kCharacterRects, 0, sizeof(kCharacterRects));
  kCharacterRects[kCharacterMap['W']].size = CGSizeMake(7, 0);
  kCharacterRects[kCharacterMap['1']].size = CGSizeMake(4, 0);
  kCharacterRects[kCharacterMap['.']].size = CGSizeMake(3, 0);
  kCharacterRects[kCharacterMap[':']].size = CGSizeMake(3, 0);

  CGRect rect = CGRectMake(0, 0, kStandardCharacterSize.width, kStandardCharacterSize.height);
  for (NSInteger ix = 0; ix < kNumberOfCharacters; ++ix) {
    CGRect characterRect = kCharacterRects[ix];
    characterRect.origin = rect.origin;

    if (characterRect.size.width == 0) {
      characterRect.size.width = rect.size.width;
    }
    if (characterRect.size.height == 0) {
      characterRect.size.height = rect.size.height;
    }

    if (CGRectGetMaxX(rect) > kFontImage.size.width) {
      rect.origin.x = 0;
      rect.origin.y += rect.size.height;
    }

    kCharacterRects[ix] = characterRect;
    rect.origin.x += characterRect.size.width;

    rect.size = kStandardCharacterSize;
  }
}

@end
