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

#import "PHPixelDriverWindow.h"

#import "PHHeaderView.h"
#import "PHDualVizualizersView.h"

static const CGSize kMinimumWindowSize = {600, 400};

static NSString* const kPixelDriverWindowFrameName = @"kPixelDriverWindowFrameName";

@implementation PHPixelDriverWindow

- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSUInteger)aStyle
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)flag {
  if ((self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag])) {
    [self setMinSize:kMinimumWindowSize];
    [self setFrameAutosaveName:kPixelDriverWindowFrameName];
    [self setAcceptsMouseMovedEvents:YES];
    [self setMovableByWindowBackground:YES];

    self.contentView = [[PHDualVizualizersView alloc] initWithFrame:[self.contentView bounds]];
  }
  return self;
}

@end
