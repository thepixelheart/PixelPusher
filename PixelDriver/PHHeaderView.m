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
#import "PHSystem.h"
#import "AppDelegate.h"
#import "PHCircularSlider.h"

static const CGFloat kLogoInset = 3;
static const NSEdgeInsets kLogoInsets = {kLogoInset, kLogoInset, kLogoInset, kLogoInset};

@interface PHHeaderView () <PHButtonDelegate>
@end

@implementation PHHeaderView {
  PHButton* _umanoModeButton;
  PHButton* _libraryButton;
  PHButton* _prefsButton;
  PHButton* _compositeEditorButton;

  PHCircularSlider* _masterFadeSlider;
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

    _umanoModeButton = [[PHButton alloc] init];
    _umanoModeButton.tag = PHSystemButtonUmanoMode;
    if ([PHSys() umanoMode]) {
      [_umanoModeButton setTextColor:[NSColor orangeColor]];
    } else {
      [_umanoModeButton setTextColor:[NSColor whiteColor]];
    }
    [_umanoModeButton setTitle:@"Umano Mode"];
    _umanoModeButton.delegate = self;
    [self.contentView addSubview:_umanoModeButton];
    
    _libraryButton = [[PHButton alloc] init];
    _libraryButton.tag = PHSystemButtonLibrary;
    [_libraryButton setTitle:@"Library"];
    _libraryButton.delegate = self;
    [self.contentView addSubview:_libraryButton];

    _prefsButton = [[PHButton alloc] init];
    _prefsButton.tag = PHSystemButtonPrefs;
    [_prefsButton setTitle:@"Prefs"];
    _prefsButton.delegate = self;
    [self.contentView addSubview:_prefsButton];

    _compositeEditorButton = [[PHButton alloc] init];
    _compositeEditorButton.tag = PHSystemButtonCompositeEditor;
    [_compositeEditorButton setTitle:@"Composite Editor"];
    _compositeEditorButton.delegate = self;
    [self.contentView addSubview:_compositeEditorButton];

    _masterFadeSlider = [[PHCircularSlider alloc] init];
    _masterFadeSlider.circularSliderType = PHCircularSliderType_Volume;
    _masterFadeSlider.volume = [PHSys() masterFade];
    _masterFadeSlider.tag = PHSystemVolumeMaster;
    _masterFadeSlider.target = self;
    _masterFadeSlider.action = @selector(sliderDidChange:);
    [_masterFadeSlider setToolTip:@"Master Fade"];
    [self.contentView addSubview:_masterFadeSlider];

    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(didChangeViewStateNotification:) name:PHSystemViewStateChangedNotification object:nil];    
  }
  return self;
}

- (void)layout {
  [super layout];

  CGSize boundsSize = self.contentView.bounds.size;

  [_prefsButton sizeToFit];
  [_compositeEditorButton sizeToFit];
  [_libraryButton sizeToFit];
  [_umanoModeButton sizeToFit];
  [_masterFadeSlider sizeToFit];

  CGFloat topMargin = floor((boundsSize.height - _prefsButton.frame.size.height) / 2);
  CGFloat leftEdge = topMargin;

  _prefsButton.frame = CGRectMake(boundsSize.width - _prefsButton.frame.size.width - leftEdge,
                                  topMargin,
                                  _prefsButton.frame.size.width, _prefsButton.frame.size.height);
  leftEdge = _prefsButton.frame.origin.x - topMargin;

  topMargin = floor((boundsSize.height - _compositeEditorButton.frame.size.height) / 2);
  _compositeEditorButton.frame = CGRectMake(leftEdge - _compositeEditorButton.frame.size.width,
                                            topMargin,
                                            _compositeEditorButton.frame.size.width, _compositeEditorButton.frame.size.height);
  leftEdge = _compositeEditorButton.frame.origin.x - topMargin;

  topMargin = floor((boundsSize.height - _libraryButton.frame.size.height) / 2);
  _libraryButton.frame = CGRectMake(leftEdge - _libraryButton.frame.size.width,
                                    topMargin,
                                    _libraryButton.frame.size.width, _libraryButton.frame.size.height);
  
  leftEdge = _libraryButton.frame.origin.x - topMargin;

  topMargin = floor((boundsSize.height - _umanoModeButton.frame.size.height) / 2);
  _umanoModeButton.frame = CGRectMake(leftEdge - _umanoModeButton.frame.size.width,
                                    topMargin,
                                    _umanoModeButton.frame.size.width, _umanoModeButton.frame.size.height);

  leftEdge = _umanoModeButton.frame.origin.x - 10;

  _masterFadeSlider.frame = CGRectMake(leftEdge - _masterFadeSlider.frame.size.width,
                                       floor((boundsSize.height - _masterFadeSlider.frame.size.height) / 2),
                                       _masterFadeSlider.frame.size.width, _masterFadeSlider.frame.size.height);
}

#pragma mark - PHButtonDelegate

- (void)didPressDownButton:(PHButton *)button {
  [PHSys() didPressButton:(PHSystemControlIdentifier)button.tag];
}

- (void)didReleaseButton:(PHButton *)button {
  [PHSys() didReleaseButton:(PHSystemControlIdentifier)button.tag];
}

#pragma mark - PHCircularSlider

- (void)sliderDidChange:(PHCircularSlider *)slider {
  if (slider.circularSliderType == PHCircularSliderType_Volume) {
    [PHSys() didChangeVolumeControl:(PHSystemControlIdentifier)slider.tag volume:slider.volume];
  }
}

#pragma mark - View Mode Notifications

- (void)didChangeViewStateNotification:(NSNotification *)notification {
  if ([PHSys() umanoMode]) {
    [_umanoModeButton setTextColor:[NSColor orangeColor]];
  } else {
    [_umanoModeButton setTextColor:[NSColor whiteColor]];
  }
}


@end
