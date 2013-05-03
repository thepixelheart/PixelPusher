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

#import "PHScript.h"

#import <FScript/FScript.h>

static NSString* const kInitDelim = @"==init==";
static NSString* const kAnimDelim = @"==anim==";

@interface PHRenderer : NSObject
@property (nonatomic, assign) CGContextRef cx;
@end

@implementation PHRenderer

- (void)fillRect:(CGRect)rect {
  CGContextFillRect(_cx, rect);
}

- (void)strokeRect:(CGRect)rect {
  CGContextStrokeRect(_cx, rect);
}

- (void)clipRect:(CGRect)rect {
  CGContextClipToRect(_cx, rect);
}

- (void)fillEllipse:(CGRect)rect {
  CGContextFillEllipseInRect(_cx, rect);
}

- (void)strokeEllipse:(CGRect)rect {
  CGContextStrokeEllipseInRect(_cx, rect);
}

@end

@interface PHScript()
@property (nonatomic, strong) FSInterpreter* interpreter;
@end

@implementation PHScript {
  NSString* _fullScript;

  NSString* _initScript;
  NSString* _animationScript;

  NSMutableDictionary* _globalVars;
}

- (id)initWithString:(NSString *)string sourceFile:(NSString *)sourceFile {
  if ((self = [super init])) {
    _fullScript = [string copy];
    _sourceFile = sourceFile;
    [self compileScript];
  }
  return self;
}

#pragma mark - Compilation

- (void)compileScript {
  _initScript = nil;
  _animationScript = nil;
  _interpreter = nil;
  _globalVars = nil;

  NSInteger startOfInit = 0;
  NSInteger endOfInit = _fullScript.length;
  NSInteger startOfAnim = 0;
  NSInteger endOfAnim = _fullScript.length;
  NSRange rangeOfInitDelim = [_fullScript rangeOfString:kInitDelim options:NSCaseInsensitiveSearch];
  if (rangeOfInitDelim.length > 0) {
    startOfInit = NSMaxRange(rangeOfInitDelim) + 1;
  }
  NSRange rangeOfAnimDelim = [_fullScript rangeOfString:kAnimDelim options:NSCaseInsensitiveSearch];
  if (rangeOfAnimDelim.length > 0) {
    endOfInit = rangeOfAnimDelim.location;
    startOfAnim = NSMaxRange(rangeOfAnimDelim) + 1;
  }

  if (startOfAnim < startOfInit) {
    NSLog(@"Anim must be after init.");
    return;
  }

  if (startOfInit > 0) {
    _initScript = [[_fullScript substringWithRange:NSMakeRange(startOfInit, endOfInit - startOfInit)]
                   stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  }
  if (startOfAnim > 0 || (startOfAnim == 0 && startOfInit == 0)) {
    _animationScript = [[_fullScript substringWithRange:NSMakeRange(startOfAnim, endOfAnim - startOfAnim)]
                        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  }

  _interpreter = [[FSInterpreter alloc] init];

  if (_initScript.length > 0) {
    _globalVars = [NSMutableDictionary dictionary];
    FSInterpreterResult *execResult = [_interpreter execute:_initScript];
    if (![execResult isOK]) {
      NSLog(@"%@ , character %ld\n", [execResult errorMessage], [execResult errorRange].location);
    }

    for (NSString* identifier in [_interpreter identifiers]) {
      id value = [_interpreter objectForIdentifier:identifier found:nil];
      [_globalVars setObject:value forKey:identifier];
    }
  }
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  if (_animationScript.length > 0) {
    NSGraphicsContext* previousContext = [NSGraphicsContext currentContext];
    NSGraphicsContext* graphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:cx flipped:NO];
    [NSGraphicsContext setCurrentContext:graphicsContext];

    PHRenderer* renderer = [[PHRenderer alloc] init];
    renderer.cx = cx;
    [_interpreter setObject:renderer forIdentifier:@"renderer"];
    for (id key in _globalVars) {
      [_interpreter setObject:_globalVars[key] forIdentifier:key];
    }
    FSInterpreterResult *execResult = [_interpreter execute:_animationScript];
    if (![execResult isOK]) {
      NSLog(@"%@ , character %ld\n", [execResult errorMessage], [execResult errorRange].location);
    } else {
      NSMutableDictionary* vars = [_globalVars copy];
      for (NSString* identifier in vars) {
        id value = [_interpreter objectForIdentifier:identifier found:nil];
        [_globalVars setObject:value forKey:identifier];
      }
    }

    [NSGraphicsContext setCurrentContext:previousContext];
  }
}

#pragma mark - Public Methods

- (void)updateWithString:(NSString *)string {
  if (![string isEqualToString:_fullScript]) {
    _fullScript = [string copy];

    [self compileScript];
  }
}

@end
