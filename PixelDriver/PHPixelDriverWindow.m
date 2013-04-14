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

#import "AppDelegate.h"
#import "PHHeaderView.h"
#import "PHDualVizualizersView.h"
#import "PHSystem.h"

static const CGSize kMinimumWindowSize = {1000, 700};

static NSString* const kPixelDriverWindowFrameName = @"kPixelDriverWindowFrameName";

@implementation PHPixelDriverWindow {
  NSInteger _focusedList;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSUInteger)aStyle
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)flag {
  if ((self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag])) {
    [self setMinSize:kMinimumWindowSize];
    [self setFrameAutosaveName:kPixelDriverWindowFrameName];
//    [self setAcceptsMouseMovedEvents:YES];
//    [self setMovableByWindowBackground:YES];

    self.contentView = [[PHDualVizualizersView alloc] initWithFrame:[self.contentView bounds]];

    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(systemSliderDidChange:) name:PHSystemSliderMovedNotification object:nil];
    [nc addObserver:self selector:@selector(systemButtonWasPressed:) name:PHSystemButtonPressedNotification object:nil];
    [nc addObserver:self selector:@selector(systemButtonWasReleased:) name:PHSystemButtonReleasedNotification object:nil];
    [nc addObserver:self selector:@selector(didRotateKnob:) name:PHSystemKnobTurnedNotification object:nil];
    [nc addObserver:self selector:@selector(focusDidChange:) name:PHSystemFocusDidChangeNotification object:nil];
  }
  return self;
}

- (void)sendEvent:(NSEvent *)theEvent {
  BOOL didHandle = NO;

  NSMutableDictionary* keyMappings = [@{
    @" ": @(PHSystemButtonPixelHeart),
    @"`": @(PHSystemButtonPixelHeart),
    @"[": @(PHSystemButtonLoadLeft),
    @"]": @(PHSystemButtonLoadRight),
    @"p": @(PHSystemButtonPrefs),
    @"l": @(PHSystemButtonLibrary),
    @"c": @(PHSystemButtonCompositeEditor),
  } mutableCopy];

  if (PHSys().viewMode == PHViewModeCompositeEditor) {
    keyMappings[@"n"] = @(PHSystemButtonNewComposite);
    keyMappings[@"51"] = @(PHSystemButtonClearCompositeActiveLayer); // Backspace
    keyMappings[@"36"] = @(PHSystemButtonLoadCompositeIntoActiveLayer); // Enter
  }

  if ((theEvent.type ==
       NSKeyDown || theEvent.type == NSKeyUp)
      && (nil != keyMappings[theEvent.charactersIgnoringModifiers]
          || nil != keyMappings[[NSString stringWithFormat:@"%d", theEvent.keyCode]])) {
    id value = keyMappings[theEvent.charactersIgnoringModifiers];
    if (nil == value) {
      value = keyMappings[[NSString stringWithFormat:@"%d", theEvent.keyCode]];
    }
    PHSystemControlIdentifier button = [value intValue];
    if (theEvent.type == NSKeyDown) {
      [PHSys() didPressButton:button];
    } else {
      [PHSys() didReleaseButton:button];
    }

    didHandle = YES;
  }

  if (!didHandle) {
    [super sendEvent:theEvent];
  }
}

#pragma mark - Notifications

- (void)systemSliderDidChange:(NSNotification *)notification {
  PHSystemControlIdentifier identifier = [notification.userInfo[PHSystemIdentifierKey] intValue];
  NSSlider* slider = [self.contentView viewWithTag:identifier];
  CGFloat value = [notification.userInfo[PHSystemValueKey] doubleValue];
  [slider setFloatValue:value];
}

- (void)systemButtonWasPressed:(NSNotification *)notification {
  PHSystemControlIdentifier identifier = [notification.userInfo[PHSystemIdentifierKey] intValue];
  NSButton* button = [self.contentView viewWithTag:identifier];
  [button setState:NSOnState];
}

- (void)systemButtonWasReleased:(NSNotification *)notification {
  PHSystemControlIdentifier identifier = [notification.userInfo[PHSystemIdentifierKey] intValue];
  NSButton* button = [self.contentView viewWithTag:identifier];
  [button setState:NSOffState];
}

- (void)didRotateKnob:(NSNotification *)notification {
  PHSystemControlIdentifier identifier = [notification.userInfo[PHSystemIdentifierKey] intValue];
  PHSystemKnobDirection direction = [notification.userInfo[PHSystemValueKey] intValue];
  id view = [self.contentView viewWithTag:identifier];
  id targetView = nil;
  NSScrollView *scrollView = nil;

  if ([view isKindOfClass:[NSScrollView class]]) {
    scrollView = view;
    targetView = [scrollView documentView];
  } else {
    targetView = view;
  }
  if ([targetView isKindOfClass:[NSCollectionView class]]) {
    NSCollectionView* collectionView = targetView;
    if (collectionView.content.count > 0) {
      NSIndexSet* selection = collectionView.selectionIndexes;
      NSInteger newSelection = 0;
      if (selection.count > 0) {
        newSelection = [selection firstIndex];
      }
      newSelection = newSelection + ((direction == PHSystemKnobDirectionCw) ? 1 : -1);
      newSelection = (newSelection + collectionView.content.count) % collectionView.content.count;
      [collectionView setSelectionIndexes:[NSIndexSet indexSetWithIndex:newSelection]];

      CGRect selectionFrame = [collectionView frameForItemAtIndex:newSelection];
      CGPoint offset = CGPointMake(0, selectionFrame.origin.y - scrollView.bounds.size.height / 2);
      offset.y = MAX(0, MIN(collectionView.frame.size.height - scrollView.bounds.size.height, offset.y));
      [scrollView.contentView scrollToPoint:offset];
    }
  } else if ([targetView isKindOfClass:[NSTableView class]]) {
    NSTableView* tableView = targetView;
    if (tableView.numberOfRows > 0) {
      NSInteger newSelection = tableView.selectedRow;
      newSelection = newSelection + ((direction == PHSystemKnobDirectionCw) ? 1 : -1);
      newSelection = (newSelection + tableView.numberOfRows) % tableView.numberOfRows;
      [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:newSelection] byExtendingSelection:NO];

      CGRect selectionFrame = [tableView frameOfCellAtColumn:0 row:newSelection];
      CGPoint offset = CGPointMake(0, selectionFrame.origin.y - scrollView.bounds.size.height / 2);
      offset.y = MAX(0, MIN(tableView.frame.size.height - scrollView.bounds.size.height, offset.y));
      [scrollView.contentView scrollToPoint:offset];
    }
  }
  _focusedList = identifier;
}

- (void)focusDidChange:(NSNotification *)notification {
  PHSystemControlIdentifier identifier = [notification.userInfo[PHSystemIdentifierKey] intValue];

  if (_focusedList > 0) {

    id view = [self.contentView viewWithTag:_focusedList];
    while (nil != view && ![view isKindOfClass:[PHContainerView class]]) {
      view = [view superview];
    }

    [view setFocused:NO];
  }

  id view = [self.contentView viewWithTag:identifier];
  while (nil != view && ![view isKindOfClass:[PHContainerView class]]) {
    view = [view superview];
  }

  PHContainerView *containerView = view;
  containerView.focused = YES;

  _focusedList = identifier;
}

@end
