//
//  PHLaunchpadWindow.m
//  PixelDriver
//
//  Created by Jeff Verkoeyen on 12/22/12.
//  Copyright (c) 2012 Pixel Heart. All rights reserved.
//

#import "PHLaunchpadWindow.h"

@implementation PHLaunchpadWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
  if ((self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag])) {
    self.opaque = NO;
    self.backgroundColor = [NSColor clearColor];
  }
  return self;
}

@end
