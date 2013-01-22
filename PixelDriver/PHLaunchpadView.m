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

#import "PHLaunchpadView.h"

#import "AppDelegate.h"
#import "PHLaunchpadMIDIDriver.h"
#import "PHMIDIMessage+Launchpad.h"

@interface PHLaunchpadButtonCell : NSButtonCell
@property (nonatomic, assign) PHLaunchpadColor color;
@end

@interface PHLaunchpadButton : NSButton
@end

@implementation PHLaunchpadButton

+ (Class)cellClass {
  return [PHLaunchpadButtonCell class];
}

- (void)viewDidMoveToWindow {
  [super viewDidMoveToWindow];

  [self addTrackingRect:self.bounds owner:self userData:NULL assumeInside:NO];
}

- (void)mouseEntered:(NSEvent *)theEvent {
  [super mouseEntered:theEvent];
  
  [self.target performSelector:@selector(mouseDidEnterButton:) withObject:self];
}

- (void)mouseExited:(NSEvent *)theEvent {
  [super mouseExited:theEvent];

  [self.target performSelector:@selector(mouseDidLeaveButton:) withObject:self];
}

@end

@implementation PHLaunchpadButtonCell {
  BOOL _square;
  NSTimer* _strobeTimer;
  PHLaunchpadColor _strobeColor;
}

- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  [self.target performSelector:self.action withObject:self];
#pragma clang diagnostic pop

  return [super startTrackingAt:startPoint inView:controlView];
}

- (id)initTextCell:(NSString *)aString {
  if ((self = [super initTextCell:aString])) {
    _color = PHLaunchpadColorOff;
  }
  return self;
}

- (id)initSquareButton {
  if ((self = [self initTextCell:nil])) {
    self.backgroundColor = [NSColor redColor];
    _square = YES;
  }
  return self;
}

- (id)initRoundButton {
  if ((self = [self initTextCell:nil])) {
    self.backgroundColor = [NSColor greenColor];
    _square = NO;
  }
  return self;
}

- (void)setColor:(PHLaunchpadColor)color {
  _color = color;

  [_strobeTimer invalidate];
  _strobeTimer = nil;

  [self.controlView setNeedsDisplay:YES];
}

- (NSColor *)NSColorFromLaunchpadColor:(PHLaunchpadColor)color {
  CGFloat dimValue = 0.4;
  CGFloat brightValue = 0.85;
  NSColor* nsColor;
  switch (color) {
    case PHLaunchpadColorOff:
      nsColor = [NSColor colorWithDeviceRed:0.5 green:0.5 blue:0.5 alpha:1];
      break;
      
    case PHLaunchpadColorRedDim:
      nsColor = [NSColor colorWithDeviceRed:dimValue green:0 blue:0 alpha:1];
      break;
      
    case PHLaunchpadColorRedFlashing:
    case PHLaunchpadColorRedBright:
      nsColor = [NSColor colorWithDeviceRed:brightValue green:0 blue:0 alpha:1];
      break;
      
    case PHLaunchpadColorAmberDim:
      nsColor = [NSColor colorWithDeviceRed:dimValue green:dimValue / 2 blue:0 alpha:1];
      break;
      
    case PHLaunchpadColorAmberFlashing:
    case PHLaunchpadColorAmberBright:
      nsColor = [NSColor colorWithDeviceRed:brightValue green:dimValue blue:0 alpha:1];
      break;
      
    case PHLaunchpadColorYellowFlashing:
    case PHLaunchpadColorYellowBright:
      nsColor = [NSColor colorWithDeviceRed:brightValue green:brightValue blue:0 alpha:1];
      break;
      
    case PHLaunchpadColorGreenDim:
      nsColor = [NSColor colorWithDeviceRed:0 green:dimValue blue:0 alpha:1];
      break;
      
    case PHLaunchpadColorGreenFlashing:
    case PHLaunchpadColorGreenBright:
      nsColor = [NSColor colorWithDeviceRed:0 green:brightValue blue:0 alpha:1];
      break;
      
    default:
      nsColor = nil;
      break;
  }

  if (color == PHLaunchpadColorRedFlashing
      || color == PHLaunchpadColorAmberFlashing
      || color == PHLaunchpadColorYellowFlashing
      || color == PHLaunchpadColorGreenFlashing) {
    _strobeColor = color;
    [_strobeTimer invalidate];
    _strobeTimer = [NSTimer scheduledTimerWithTimeInterval:0.15 target:self selector:@selector(strobeTimerDidFire:) userInfo:nil repeats:YES];
  }

  return nsColor;
}

- (void)strobeTimerDidFire:(NSTimer *)timer {
  if (_color == _strobeColor) {
    _color = PHLaunchpadColorOff;
  } else {
    _color = _strobeColor;
  }
  [self.controlView setNeedsDisplay:YES];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  [NSGraphicsContext saveGraphicsState];

  NSColor* buttonColor = [self NSColorFromLaunchpadColor:_color];
  CGFloat r = 0;
  CGFloat g = 0;
  CGFloat b = 0;
  CGFloat a = 0;
  [buttonColor getRed:&r green:&g blue:&b alpha:&a];
  CGFloat h = 0;
  CGFloat s = 0;
  CGFloat br = 0;
  [buttonColor getHue:&h saturation:&s brightness:&br alpha:nil];
  NSColor* highlightedButtonColor = [NSColor colorWithDeviceHue:h saturation:MAX(0, s * 0.5) brightness:MIN(1, br * 1.4) alpha:a];
  CGFloat rh = 0;
  CGFloat gh = 0;
  CGFloat bh = 0;
  CGFloat ah = 0;
  [highlightedButtonColor getRed:&rh green:&gh blue:&bh alpha:&ah];

  if (self.isHighlighted && _color != PHLaunchpadColorOff) {
    NSColor* highlightedButtonColor = [NSColor colorWithDeviceHue:h saturation:MAX(0, s * 0.2) brightness:MIN(1, br * 1.4) alpha:a];
    [highlightedButtonColor getRed:&rh green:&gh blue:&bh alpha:&ah];
  }

  CGContextRef cx = [[NSGraphicsContext currentContext] graphicsPort];

  if (_square) {
    CGFloat radius = 5;
    CGRect rect = cellFrame;
    // http://stackoverflow.com/questions/1031930/how-is-a-rounded-rect-view-with-transparency-done-on-iphone/1031936#1031936

    // Top left
    CGContextMoveToPoint(cx, rect.origin.x, rect.origin.y + radius);

    // Left edge
    CGContextAddLineToPoint(cx, rect.origin.x, rect.origin.y + rect.size.height - radius);

    // Bottom left corner
    if (self.tag == 28) {
      CGContextAddLineToPoint(cx, rect.origin.x + radius, rect.origin.y + rect.size.height);
    } else {
      CGContextAddArc(cx, rect.origin.x + radius, rect.origin.y + rect.size.height - radius,
                      radius, M_PI, M_PI / 2, 1);
    }

    // Bottom edge
    CGContextAddLineToPoint(cx, rect.origin.x + rect.size.width - radius,
                            rect.origin.y + rect.size.height);

    // Bottom right corner
    if (self.tag == 27) {
      CGContextAddLineToPoint(cx, rect.origin.x + rect.size.width,
                              rect.origin.y + rect.size.height - radius);
    } else {
      CGContextAddArc(cx, rect.origin.x + rect.size.width - radius,
                      rect.origin.y + rect.size.height - radius, radius, M_PI / 2, 0.0f, 1);
    }

    // Right edge
    CGContextAddLineToPoint(cx, rect.origin.x + rect.size.width, rect.origin.y + radius);

    // Top right corner
    if (self.tag == 35) {
      CGContextAddLineToPoint(cx, rect.origin.x + rect.size.width - radius, rect.origin.y);
    } else {
      CGContextAddArc(cx, rect.origin.x + rect.size.width - radius, rect.origin.y + radius,
                      radius, 0.0f, -M_PI / 2, 1);
    }

    // Top edge
    CGContextAddLineToPoint(cx, rect.origin.x + radius, rect.origin.y);

    // Top left corner
    if (self.tag == 36) {
      CGContextAddLineToPoint(cx, rect.origin.x, rect.origin.y + radius);
    } else {
      CGContextAddArc(cx, rect.origin.x + radius, rect.origin.y + radius, radius,
                      -M_PI / 2, M_PI, 1);
    }

    if (self.isHighlighted || _color != PHLaunchpadColorOff) {
      size_t num_locations = 2;
      CGFloat locations[2] = { 0, 1 };
      CGFloat components[8] = {
        rh, gh, bh, ah,
        r, g, b, a
      };

      CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
      CGGradientRef gradient = CGGradientCreateWithColorComponents(cs, components, locations, num_locations);
      CGColorSpaceRelease(cs);

      CGContextClip(cx);

      CGPoint midPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
      CGContextDrawRadialGradient(cx, gradient, midPoint,
                                   0, midPoint, rect.size.width,
                                   kCGGradientDrawsBeforeStartLocation);
      CGGradientRelease(gradient);

    } else {
      CGContextSetFillColorWithColor(cx, buttonColor.CGColor);
      CGContextFillPath(cx);
    }
  } else {
    // Rounded circle cells are really big and a fixed size for some reason, so
    // we need to compensate for that fact.
    CGRect circleFrame = cellFrame;
    circleFrame.origin.x += 4;
    circleFrame.origin.y += 1;
    circleFrame.size.width -= 9;
    circleFrame.size.height -= 8;
    if (self.isHighlighted || _color != PHLaunchpadColorOff) {
      size_t num_locations = 2;
      CGFloat locations[2] = { 0, 1 };
      CGFloat components[8] = {
        rh, gh, bh, ah,
        r, g, b, a
      };

      CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
      CGGradientRef gradient = CGGradientCreateWithColorComponents(cs, components, locations, num_locations);
      CGColorSpaceRelease(cs);

      CGPoint midPoint = CGPointMake(CGRectGetMidX(circleFrame), CGRectGetMidY(circleFrame));
      CGContextDrawRadialGradient(cx, gradient, midPoint,
                                  0, midPoint, circleFrame.size.width / 2,
                                  kCGGradientDrawsBeforeStartLocation);
      CGGradientRelease(gradient);
    } else {
      CGContextSetFillColorWithColor(cx, buttonColor.CGColor);
      CGContextFillEllipseInRect(cx, circleFrame);
    }
  }

  [NSGraphicsContext restoreGraphicsState];
}

@end

@implementation PHLaunchpadView

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
  [super awakeFromNib];

  NSArray* views = [self.subviews copy];
  for (NSView* view in views) {
    if ([view isKindOfClass:[NSButton class]]) {
      NSButton* button = (NSButton *)view;

      if (button.tag < 64) {
        button.cell = [[PHLaunchpadButtonCell alloc] initSquareButton];
      } else {
        button.cell = [[PHLaunchpadButtonCell alloc] initRoundButton];
      }
      [button.cell setTag:button.tag];
      button.target = self;
      button.action = @selector(didTapButton:);
    }
  }

  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self
         selector:@selector(midiDidSendMessageNotification:)
             name:PHLaunchpadDidSendMIDIMessagesNotification
           object:nil];
}

- (void)drawRect:(NSRect)dirtyRect {
  [NSGraphicsContext saveGraphicsState];

  [[NSColor colorWithDeviceRed:0.1 green:0.1 blue:0.1 alpha:1] set];
  CGContextRef cx = [[NSGraphicsContext currentContext] graphicsPort];

  CGFloat radius = 20;
  CGRect rect = self.bounds;
  // http://stackoverflow.com/questions/1031930/how-is-a-rounded-rect-view-with-transparency-done-on-iphone/1031936#1031936
  CGContextMoveToPoint(cx, rect.origin.x, rect.origin.y + radius);
  CGContextAddLineToPoint(cx, rect.origin.x, rect.origin.y + rect.size.height - radius);
  CGContextAddArc(cx, rect.origin.x + radius, rect.origin.y + rect.size.height - radius,
                  radius, M_PI, M_PI / 2, 1);
  CGContextAddLineToPoint(cx, rect.origin.x + rect.size.width - radius,
                          rect.origin.y + rect.size.height);
  CGContextAddArc(cx, rect.origin.x + rect.size.width - radius,
                  rect.origin.y + rect.size.height - radius, radius, M_PI / 2, 0.0f, 1);
  CGContextAddLineToPoint(cx, rect.origin.x + rect.size.width, rect.origin.y + radius);
  CGContextAddArc(cx, rect.origin.x + rect.size.width - radius, rect.origin.y + radius,
                  radius, 0.0f, -M_PI / 2, 1);
  CGContextAddLineToPoint(cx, rect.origin.x + radius, rect.origin.y);
  CGContextAddArc(cx, rect.origin.x + radius, rect.origin.y + radius, radius,
                  -M_PI / 2, M_PI, 1);

  CGContextFillPath(cx);

  [NSGraphicsContext restoreGraphicsState];

  [super drawRect:dirtyRect];
}

- (IBAction)didTapButton:(NSButton *)sender {
  PHLaunchpadEvent event;
  int buttonIndex;
  if (sender.tag < 64) {
    event = PHLaunchpadEventGridButtonState;
    buttonIndex = (int)sender.tag;
  } else if (sender.tag < 72) {
    event = PHLaunchpadEventTopButtonState;
    buttonIndex = (int)sender.tag - 64;
  } else {
    event = PHLaunchpadEventRightButtonState;
    buttonIndex = (int)sender.tag - 72;
  }
  NSDictionary* userInfo =
  @{PHLaunchpadEventTypeUserInfoKey: [NSNumber numberWithInt:event],
    PHLaunchpadButtonPressedUserInfoKey: [NSNumber numberWithBool:[sender isKindOfClass:[NSCell class]]],
    PHLaunchpadButtonIndexInfoKey: [NSNumber numberWithInt:buttonIndex]};

  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:PHLaunchpadDidReceiveStateChangeNotification object:nil userInfo:userInfo];

  // TODO: Add support for tooltips again.
  //[PHApp() bringTooltipForward];
}

- (void)midiDidSendMessageNotification:(NSNotification *)notification {
  if ([NSThread currentThread] != [NSThread mainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self midiDidSendMessageNotification:notification];
    });
    return;
  }
  NSArray* messages = [notification.userInfo objectForKey:PHLaunchpadMessagesUserInfoKey];
  for (PHMIDIMessage* midiMessage in messages) {
    if (midiMessage.status == PHMIDIStatusControlChange) {
      if (midiMessage.data1 == 0 && midiMessage.data2 == 0) {
        // Reset
        for (NSView* view in self.subviews) {
          if ([view isKindOfClass:[NSButton class]]) {
            NSButton* button = (NSButton *)view;
            PHLaunchpadButtonCell* cell = button.cell;
            cell.color = PHLaunchpadColorOff;
          }
        }
        continue;
      } else if (midiMessage.data1 == 0) {
        continue;
      }
    }
    if (midiMessage.status == PHMIDIStatusNoteOn
        || midiMessage.status == PHMIDIStatusControlChange) {
      // Changing a button color.
      int launchpadColor = 0;
      for (int ix = 0; ix < PHLaunchpadColorCount; ++ix) {
        if (PHLaunchpadColorToByte[ix] == midiMessage.data2) {
          launchpadColor = ix;
          break;
        }
      }

      int buttonIndex = midiMessage.launchpadButtonIndex;
      PHLaunchpadEvent event = midiMessage.launchpadEvent;
      int tag;
      if (event == PHLaunchpadEventGridButtonState) {
        tag = buttonIndex;
      } else if (event == PHLaunchpadEventTopButtonState) {
        tag = buttonIndex + 64;
      } else {
        tag = buttonIndex + 72;
      }

      NSButton* button = [self viewWithTag:tag];
      PHLaunchpadButtonCell* cell = button.cell;
      cell.color = launchpadColor;
    }
  }
}

- (void)mouseDidEnterButton:(NSButton *)button {
  // TODO: Add support for tooltips again.
  /*NSString* tooltip = nil;
  if (button.tag < 64) {
    tooltip = [PHApp() tooltipForButtonIndex:button.tag];

  } else if (button.tag < 72) {
    tooltip = [PHApp() tooltipForTopButtonIndex:button.tag - 64];

  } else {
    tooltip = [PHApp() tooltipForSideButtonIndex:button.tag - 72];
  }

  [PHApp() pointTooltipAtView:button withString:tooltip];*/
}

- (void)mouseDidLeaveButton:(NSButton *)button {
  // TODO: Add support for tooltips again.
  //[PHApp() hideTooltip];
}

@end
