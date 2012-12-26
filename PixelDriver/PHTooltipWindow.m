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

#import "PHTooltipWindow.h"

#import "PHTooltipView.h"

@implementation PHTooltipWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
  if ((self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag])) {
    self.opaque = NO;
    self.backgroundColor = [NSColor clearColor];
  }
  return self;
}

- (void)setTooltip:(NSString *)tooltip {
  [self.tooltipView.textField setStringValue:tooltip];
  [self.tooltipView.textField sizeToFit];

  CGRect windowFrame = CGRectMake(0, 0, self.tooltipView.textField.frame.size.width + 20, self.tooltipView.textField.frame.size.height + 20);
  [self setFrame:windowFrame display:NO];
  [self.tooltipView.textField setFrame:CGRectInset(windowFrame, 10, 10)];
}

@end
