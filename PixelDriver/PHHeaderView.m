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

#import "PHDualVizualizersView.h"
#import "PHPixelImageView.h"
#import "PHButton.h"

static const CGFloat kLogoInset = 3;
static const NSEdgeInsets kLogoInsets = {kLogoInset, kLogoInset, kLogoInset, kLogoInset};

@implementation PHHeaderView {
  PHButton* _prefsButton;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObject:self];
}

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

    _prefsButton = [[PHButton alloc] init];
    [_prefsButton setTitle:@"Prefs"];
    _prefsButton.target = self;
    _prefsButton.action = @selector(didTapPrefsButton:);
    [self.contentView addSubview:_prefsButton];

    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(didChangeViewMode:) name:PHChangeCurrentViewNotification object:nil];
  }
  return self;
}

- (void)layout {
  [super layout];

  CGSize boundsSize = self.contentView.bounds.size;
  [_prefsButton sizeToFit];
  CGFloat topMargin = floor((boundsSize.height - _prefsButton.frame.size.height) / 2);
  _prefsButton.frame = CGRectMake(boundsSize.width - _prefsButton.frame.size.width - topMargin,
                                  topMargin,
                                  _prefsButton.frame.size.width, _prefsButton.frame.size.height);
}

#pragma mark - User Actions

- (void)didTapPrefsButton:(NSButton *)button {
  [_delegate didTapPrefsButton];
}

- (void)didChangeViewMode:(NSNotification *)notification {
  PHViewMode viewMode = [notification.userInfo[PHChangeCurrentViewKey] intValue];
  if (viewMode != PHViewModePrefs) {
    [_prefsButton setTitle:@"Prefs"];
  } else {
    [_prefsButton setTitle:@"Library"];
  }
  [self setNeedsLayout:YES];
}

@end
