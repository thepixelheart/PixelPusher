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

#import "PHPrefsView.h"

#import "PHListView.h"
#import "PHAudioPrefsPage.h"
#import "PHSpectrumAnalyzerView.h"
#import "PHWaveFormView.h"

static const CGFloat kExplorerWidth = 200;
static const CGFloat kAudioWidth = 200;

@interface PHPrefsView() <PHListViewDelegate, PHListViewDataSource>
@end

@implementation PHPrefsView {
  PHListView* _pagesView;
  NSDictionary* _nameToPrefsPageClass;
  NSArray* _prefPageNames;

  PHContainerView* _fftView;
  PHContainerView* _audioView;
  NSView* _activePageView;
}

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    _pagesView = [[PHListView alloc] init];
    _pagesView.title = @"Preferences";
    _pagesView.dataSource = self;
    _pagesView.delegate = self;
    [self addSubview:_pagesView];

    _fftView = [[PHContainerView alloc] init];
    [self addSubview:_fftView];

    PHSpectrumAnalyzerView* spectrumView = [[PHSpectrumAnalyzerView alloc] initWithFrame:_fftView.contentView.bounds];
    spectrumView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    spectrumView.audioChannel = PHAudioChannelUnified;
    [_fftView.contentView addSubview:spectrumView];

    _audioView = [[PHContainerView alloc] init];
    [self addSubview:_audioView];

    PHWaveFormView* waveFormView = [[PHWaveFormView alloc] initWithFrame:_audioView.contentView.bounds];
    waveFormView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    waveFormView.audioChannel = PHAudioChannelUnified;
    [_audioView.contentView addSubview:waveFormView];

    _nameToPrefsPageClass = @{
      @"Audio": [PHAudioPrefsPage class]
    };

    _prefPageNames = [_nameToPrefsPageClass.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString* obj1, NSString* obj2) {
      return [obj1 compare:obj2];
    }];

    [self showPageAtIndex:0];
  }
  return self;
}

- (void)layout {
  [super layout];

  CGSize boundsSize = self.bounds.size;
  _pagesView.frame = CGRectMake(0, 0, kExplorerWidth, boundsSize.height);
  [_pagesView layout];

  CGFloat pageWidth = boundsSize.width - CGRectGetMaxX(_pagesView.frame) - kAudioWidth;
  _activePageView.frame = CGRectMake(CGRectGetMaxX(_pagesView.frame), 0, pageWidth, boundsSize.height);
  [_activePageView layout];

  CGFloat leftEdge = CGRectGetMaxX(_activePageView.frame);

  _fftView.frame = CGRectMake(leftEdge, boundsSize.height - kAudioWidth, kAudioWidth, kAudioWidth);
  [_fftView layout];
  _audioView.frame = CGRectMake(leftEdge, boundsSize.height - kAudioWidth * 2, kAudioWidth, kAudioWidth);
  [_audioView layout];
}

- (void)showPageAtIndex:(NSInteger)pageIndex {
  [_activePageView removeFromSuperview];

  NSString* pageName = _prefPageNames[pageIndex];
  Class pageClass = _nameToPrefsPageClass[pageName];
  _activePageView = [[pageClass alloc] init];
  [self addSubview:_activePageView];

  [self setNeedsLayout:YES];
}

#pragma mark - PHListViewDelegate

- (void)listView:(PHListView *)listView didSelectRowAtIndex:(NSInteger)index {
  if (listView == _pagesView) {
    [self showPageAtIndex:index];
  }
}

#pragma mark - PHListViewDataSource

- (NSInteger)numberOfRowsInListView:(PHListView *)listView {
  if (listView == _pagesView) {
    return _prefPageNames.count;
  } else {
    return 0;
  }
}

- (NSString *)listView:(PHListView *)listView stringForRowAtIndex:(NSInteger)index {
  if (listView == _pagesView) {
    return [_prefPageNames objectAtIndex:index];
  } else {
    return nil;
  }
}

@end
