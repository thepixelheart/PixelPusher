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

// The characters in the image must be tightly packed by row.
static const NSInteger kCharacterLocations[] = {
  'A','B','C','D','E','F','G','H','I',
  'J','K','L','M','N','O','P','Q','R',
  'S','T','U','V','W','X','Y','Z','1',
  '2','3','4','5','6','7','8','9','0','.',
  ':','+','-','\''
};
static const NSInteger kNumberOfCharacters = sizeof(kCharacterLocations) / sizeof(kCharacterLocations[0]);

// The frame of each character in the kFontImage.
static CGRect kCharacterRects[kNumberOfCharacters];

static const CGSize kStandardCharacterSize = {5,7};
static const CGSize kStandardSpaceSize = {3,7};

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
  kCharacterRects[kCharacterMap['M']].size = CGSizeMake(7, 0);
  kCharacterRects[kCharacterMap['W']].size = CGSizeMake(7, 0);
  kCharacterRects[kCharacterMap['1']].size = CGSizeMake(4, 0);
  kCharacterRects[kCharacterMap['.']].size = CGSizeMake(3, 0);
  kCharacterRects[kCharacterMap[':']].size = CGSizeMake(3, 0);
  kCharacterRects[kCharacterMap['\'']].size = CGSizeMake(3, 0);

  CGPoint offset = CGPointZero;
  for (NSInteger ix = 0; ix < kNumberOfCharacters; ++ix) {
    CGRect characterRect = kCharacterRects[ix];
    characterRect.origin = offset;

    if (characterRect.size.width == 0) {
      characterRect.size.width = kStandardCharacterSize.width;
    }
    if (characterRect.size.height == 0) {
      characterRect.size.height = kStandardCharacterSize.height;
    }

    if (CGRectGetMaxX(characterRect) > kFontImage.size.width) {
      characterRect.origin.x = 0;
      characterRect.origin.y += characterRect.size.height;
      offset = characterRect.origin;
    }

    characterRect.origin.y = kFontImage.size.height - characterRect.origin.y - characterRect.size.height;

    kCharacterRects[ix] = characterRect;
    offset.x += characterRect.size.width;
  }
}

+ (CGFloat)offsetForPreviousCharacter:(unichar)previousCharacter character:(unichar)character {
  if ((previousCharacter == 'L' && (character == '1' || character == 'Y' || character == '+' || character == 'T' || character == 'W'))
      || (previousCharacter == 'T' && (character == 'M' || character == '-' || character == '.'))
      || (previousCharacter == '-' && (character == 'T'))
      || (previousCharacter == '+' && (character == '7' || character == 'T'))
      || (previousCharacter == 'M' && character == 'T')
      || (previousCharacter == 'V' && (character == '.'))
      || (previousCharacter == 'W' && (character == '.'))
      || (previousCharacter == '.' && (character == 'W'))
      || (previousCharacter == 'Y' && character == 'J')) {
    return -1;
    
  } else if ((previousCharacter == 'L' && (character == '\'' || character == '7' || character == '9' || character == '4' || character == '-'))
             || (previousCharacter == '-' && (character == '7'))
             || (previousCharacter == 'F' && (character == '.'))
             || (previousCharacter == 'P' && (character == '.'))) {
    return -2;
  }

  return 0;
}

+ (CGSize)sizeOfString:(NSString *)string inRect:(CGRect)rect lineBreakMode:(NSLineBreakMode)lineBreakMode inContext:(CGContextRef)cx {
  string = [string uppercaseString];
  rect.origin.y = -rect.origin.y;

  NSGraphicsContext* previousContext = nil;
  if (nil != cx) {
    CGContextSaveGState(cx);

    previousContext = [NSGraphicsContext currentContext];
    NSGraphicsContext* graphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:cx flipped:NO];
    [NSGraphicsContext setCurrentContext:graphicsContext];
  }

  CGSize size = CGSizeMake(0, kStandardCharacterSize.height);

  BOOL wordHasBeenChecked = NO;
  unichar previousCharacter = 0;

  CGRect dstRect = CGRectMake(rect.origin.x, rect.origin.y, 0, 0);
  for (NSInteger ix = 0; ix < string.length; ++ix) {
    unichar character = [string characterAtIndex:ix];
    CGRect srcRect = kCharacterRects[kCharacterMap[character]];

    // Invisible character codes.
    if (character == ' ') {
      srcRect.size = kStandardSpaceSize;
      wordHasBeenChecked = NO;

    } else if (character == '\n') {
      dstRect.origin.x = rect.origin.x;
      dstRect.origin.y -= kStandardCharacterSize.height - 1;
      size.height += kStandardCharacterSize.height - 1;
      previousCharacter = character;
      continue;
    }

    dstRect.size = srcRect.size;

    if (lineBreakMode == NSLineBreakByCharWrapping) {
      if (CGRectGetMaxX(dstRect) > CGRectGetMaxX(rect)) {
        dstRect.origin.x = rect.origin.x;
        dstRect.origin.y -= kStandardCharacterSize.height - 1;
        size.height += kStandardCharacterSize.height - 1;
      }
    } else if (lineBreakMode == NSLineBreakByWordWrapping) {
      if (!wordHasBeenChecked) {
        CGFloat textRightEdge = CGRectGetMaxX(dstRect);
        unichar lookaheadPreviousChar = character;
        for (NSInteger ixLookahead = ix + 1;
             ixLookahead < string.length && textRightEdge < CGRectGetMaxX(rect);
             ++ixLookahead) {
          unichar lookaheadCharacter = [string characterAtIndex:ixLookahead];
          if (lookaheadCharacter == ' ') {
            break;
          }
          CGRect lookaheadRect = kCharacterRects[kCharacterMap[lookaheadCharacter]];
          textRightEdge += lookaheadRect.size.width - 1;

          textRightEdge += [self offsetForPreviousCharacter:lookaheadPreviousChar character:lookaheadCharacter];
          
          lookaheadPreviousChar = lookaheadCharacter;
        }
        if (textRightEdge > CGRectGetMaxX(rect)) {
          // Word won't fit.
          dstRect.origin.x = rect.origin.x;
          dstRect.origin.y -= kStandardCharacterSize.height - 1;
          size.height += kStandardCharacterSize.height - 1;
          
          previousCharacter = character;
          // This is a space, so skip it.
          continue;
        }
        wordHasBeenChecked = YES;
      }
    }
    
    dstRect.origin.x += [self offsetForPreviousCharacter:previousCharacter character:character];

    // Don't render invisible characters.
    if (nil != cx
        && character != ' ') {
      CGContextSaveGState(cx);
      CGContextScaleCTM(cx, 1, -1);
      CGContextTranslateCTM(cx, 0, -srcRect.size.height);
      
      [kFontImage drawInRect:dstRect fromRect:srcRect operation:NSCompositeSourceOver fraction:1];
      
      CGContextRestoreGState(cx);
    }

    size.width = MAX(size.width, rect.origin.x + CGRectGetMaxX(dstRect));

    dstRect.origin.x += dstRect.size.width - 1;
    
    previousCharacter = character;
  }
  
  if (nil != cx) {
    [NSGraphicsContext setCurrentContext:previousContext];
    CGContextRestoreGState(cx);
  }
  
  return size;
}

+ (CGFloat)lineHeight {
  return kStandardCharacterSize.height;
}

+ (CGSize)sizeOfString:(NSString *)string {
  return [self sizeOfString:string inRect:CGRectMake(0, 0, CGFLOAT_MAX, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping inContext:nil];
}

+ (CGSize)sizeOfString:(NSString *)string withConstraints:(CGSize)constraints {
  return [self sizeOfString:string inRect:CGRectMake(0, 0, constraints.width, constraints.height) lineBreakMode:NSLineBreakByWordWrapping  inContext:nil];
}

+ (CGSize)renderString:(NSString *)string atPoint:(CGPoint)point inContext:(CGContextRef)cx {
  return [self sizeOfString:string inRect:CGRectMake(point.x, point.y, CGFLOAT_MAX, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping  inContext:cx];
}

+ (CGSize)renderString:(NSString *)string inRect:(CGRect)rect inContext:(CGContextRef)cx {
  return [self sizeOfString:string inRect:rect lineBreakMode:NSLineBreakByWordWrapping  inContext:cx];
}

@end
