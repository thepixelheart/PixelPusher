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

#import "PHAudioPrefsPage.h"

#import "AppDelegate.h"
#import "PHButton.h"
#import "PHFMODRecorder.h"
#import "PHSlider.h"

static const NSEdgeInsets kContentPadding = {10, 10, 10, 10};

typedef enum {
  PHAudioPrefIdSource,
  PHAudioPrefIdDestination,
  PHAudioPrefIdPlaybackEnabled,
  PHAudioPrefIdVolume,
} PHAudioPrefId;

@implementation PHAudioPrefsPage {
  NSMutableArray* _rowsOfViewPairs;
}

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    _rowsOfViewPairs = [NSMutableArray array];
    [self addRowWithLabel:@"Audio Source" popUpButtonId:PHAudioPrefIdSource selectedIndex:PHApp().audioRecorder.recordDriverIndex];
    [self addRowWithLabel:@"Audio Destination" popUpButtonId:PHAudioPrefIdDestination selectedIndex:PHApp().audioRecorder.playbackDriverIndex];
    [self addRowWithLabel:@"Playback" buttonId:PHAudioPrefIdPlaybackEnabled];
    [self addRowWithLabel:@"Volume" sliderId:PHAudioPrefIdVolume];
  }
  return self;
}

#pragma mark - Layout

- (void)layout {
  [super layout];

  CGSize boundsSize = self.contentView.bounds.size;

  CGFloat leftColRightEdge = kContentPadding.left;

  // Calculate the widest label
  for (NSInteger ix = 0; ix < _rowsOfViewPairs.count; ix += 2) {
    NSView* leftView = _rowsOfViewPairs[ix];
    NSView* rightView = _rowsOfViewPairs[ix + 1];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL sizeToFit = @selector(sizeToFit);
    if ([leftView respondsToSelector:sizeToFit]) {
      [leftView performSelector:sizeToFit];
    }
    if ([rightView isKindOfClass:[NSSlider class]]) {
      rightView.frame = CGRectMake(0, 0, 200, 44);

    } else if ([rightView respondsToSelector:sizeToFit]) {
      [rightView performSelector:sizeToFit];
    }
#pragma clang diagnostic pop

    leftColRightEdge = MAX(leftColRightEdge, kContentPadding.left + leftView.frame.size.width);
  }

  CGFloat topEdge = boundsSize.height - kContentPadding.top;

  for (NSInteger ix = 0; ix < _rowsOfViewPairs.count; ix += 2) {
    NSView* leftView = _rowsOfViewPairs[ix];
    NSView* rightView = _rowsOfViewPairs[ix + 1];

    CGFloat bottomEdge = topEdge - MAX(leftView.frame.size.height, rightView.frame.size.height);
    CGFloat height = topEdge - bottomEdge;
    leftView.frame = CGRectMake(kContentPadding.left, bottomEdge + floor((height - leftView.frame.size.height) / 2), leftView.frame.size.width, leftView.frame.size.height);
    rightView.frame = CGRectMake(kContentPadding.left + leftColRightEdge + 10, bottomEdge + floor((height - rightView.frame.size.height) / 2), rightView.frame.size.width, rightView.frame.size.height);

    topEdge = bottomEdge - 10;
  }
}

#pragma mark - Adding Rows

- (void)addLabel:(NSString *)labelText {
  NSTextField* label = [[NSTextField alloc] init];
  [label setEditable:NO];
  [label setBezeled:NO];
  [label setBackgroundColor:nil];
  [label setTextColor:[NSColor whiteColor]];
  label.stringValue = labelText;
  [self.contentView addSubview:label];

  [_rowsOfViewPairs addObject:label];
}

- (void)addRowWithLabel:(NSString *)labelText popUpButtonId:(NSInteger)popUpButtonId selectedIndex:(NSInteger)selectedIndex {
  [self addLabel:labelText];

  NSPopUpButton* button = [[NSPopUpButton alloc] init];
  [button addItemsWithTitles:[self popUpItemTitlesForId:popUpButtonId]];
  [button selectItemAtIndex:selectedIndex];
  button.target = self;
  button.action = @selector(didChangePopUpButton:);
  button.tag = popUpButtonId;
  [self.contentView addSubview:button];

  [_rowsOfViewPairs addObject:button];
}

- (void)addRowWithLabel:(NSString *)labelText buttonId:(NSInteger)buttonId {
  [self addLabel:labelText];

  PHButton* button = [[PHButton alloc] init];
  button.title = [self titleForButtonId:buttonId];
  button.target = self;
  button.action = @selector(didTapButton:);
  button.tag = buttonId;
  [self.contentView addSubview:button];

  [_rowsOfViewPairs addObject:button];
}

- (void)addRowWithLabel:(NSString *)labelText sliderId:(NSInteger)sliderId {
  [self addLabel:labelText];

  PHSlider* slider = [[PHSlider alloc] init];
  slider.target = self;
  slider.action = @selector(didMoveSlider:);
  slider.tag = sliderId;
  slider.minValue = 0;
  slider.maxValue = 1;
  [slider setContinuous:YES];
  slider.numberOfTickMarks = 11;
  [slider setFloatValue:[self valueForSliderId:sliderId]];
  [self.contentView addSubview:slider];

  [_rowsOfViewPairs addObject:slider];
}

- (NSString *)titleForButtonId:(NSInteger)buttonId {
  if (buttonId == PHAudioPrefIdPlaybackEnabled) {
    return PHApp().audioRecorder.isListening ? @"Stop Listening" : @"Start Listening";

  } else {
    return nil;
  }
}

- (NSArray *)popUpItemTitlesForId:(NSInteger)popUpButtonId {
  if (popUpButtonId == PHAudioPrefIdSource) {
    return PHApp().audioRecorder.recordDriverNames;

  } else if (popUpButtonId == PHAudioPrefIdDestination) {
    return PHApp().audioRecorder.playbackDriverNames;
  }
  return nil;
}

- (float)valueForSliderId:(NSInteger)sliderId {
  if (sliderId == PHAudioPrefIdVolume) {
    return [PHApp().audioRecorder volume];
  }
  return 0;
}

#pragma mark - Actions

- (void)didMoveSlider:(NSSlider *)slider {
  if (slider.tag == PHAudioPrefIdVolume) {
    [PHApp().audioRecorder setVolume:slider.floatValue];
  }
}

- (void)didTapButton:(NSButton *)button {
  if (button.tag == PHAudioPrefIdPlaybackEnabled) {
    [PHApp().audioRecorder toggleListening];
  }
  [[self viewWithTag:button.tag] setTitle:[self titleForButtonId:button.tag]];
}

- (void)didChangePopUpButton:(NSPopUpButton *)button {
  if (button.tag == PHAudioPrefIdSource) {
    [PHApp().audioRecorder setRecordDriverIndex:(int)button.indexOfSelectedItem];
  } else if (button.tag == PHAudioPrefIdDestination) {
    [PHApp().audioRecorder setPlaybackDriverIndex:(int)button.indexOfSelectedItem];
  }
}

@end
