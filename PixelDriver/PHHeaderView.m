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

#import "PHHeaderView.h"

#import "PHPixelImageView.h"

static const CGFloat kLogoInset = 3;
static const NSEdgeInsets kLogoInsets = {kLogoInset, kLogoInset, kLogoInset, kLogoInset};

@implementation PHHeaderView

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    NSImageView* logoView = [[PHPixelImageView alloc] initWithFrame:NSZeroRect];
    logoView.image = [NSImage imageNamed:@"pixeldriver.png"];
    logoView.imageScaling = NSImageScaleProportionallyUpOrDown;

    CGFloat logoHeight = self.contentView.bounds.size.height - kLogoInsets.top - kLogoInsets.bottom;
    CGFloat scale = logoHeight / logoView.image.size.height;
    logoView.frame = CGRectMake(kLogoInsets.left, kLogoInsets.top,
                                logoView.image.size.width * scale, logoHeight);
    [self.contentView addSubview:logoView];
  }
  return self;
}

@end