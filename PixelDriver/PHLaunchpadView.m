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

#import "PHLaunchpadMIDIDriver.h"

@interface PHLaunchpadButtonCell : NSButtonCell
@property (nonatomic, assign) PHLaunchpadColor color;
@end

@implementation PHLaunchpadButtonCell {
  BOOL _square;
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

- (NSColor *)NSColorFromLaunchpadColor:(PHLaunchpadColor)color {
  switch (color) {
    case PHLaunchpadColorOff:
      return [NSColor colorWithDeviceRed:0.5 green:0.5 blue:0.5 alpha:1];
    case PHLaunchpadColorRedDim:
      return [NSColor colorWithDeviceRed:0.5 green:0 blue:0 alpha:1];
    case PHLaunchpadColorRedFlashing:
    case PHLaunchpadColorRedBright:
      return [NSColor colorWithDeviceRed:1 green:0 blue:0 alpha:1];
    case PHLaunchpadColorAmberDim:
      return [NSColor colorWithDeviceRed:0.5 green:0.25 blue:0 alpha:1];
    case PHLaunchpadColorAmberFlashing:
    case PHLaunchpadColorAmberBright:
      return [NSColor colorWithDeviceRed:1 green:0.5 blue:0 alpha:1];
    case PHLaunchpadColorYellowFlashing:
    case PHLaunchpadColorYellowBright:
      return [NSColor colorWithDeviceRed:1 green:1 blue:0 alpha:1];
    case PHLaunchpadColorGreenDim:
      return [NSColor colorWithDeviceRed:0 green:0.5 blue:0 alpha:1];
    case PHLaunchpadColorGreenFlashing:
    case PHLaunchpadColorGreenBright:
      return [NSColor colorWithDeviceRed:0 green:1 blue:0 alpha:1];
    default:
      return nil;
  }
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
  NSColor* highlightedButtonColor = [NSColor colorWithDeviceHue:h saturation:s brightness:MIN(1, br * 1.4) alpha:a];
  CGFloat rh = 0;
  CGFloat gh = 0;
  CGFloat bh = 0;
  CGFloat ah = 0;
  [highlightedButtonColor getRed:&rh green:&gh blue:&bh alpha:&ah];

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

    if (self.isHighlighted) {
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
    if (self.isHighlighted) {

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

- (void)awakeFromNib {
  [super awakeFromNib];

  for (NSView* view in self.subviews) {
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
  NSLog(@"%ld", sender.tag);
  [(NSButtonCell *)sender.cell setBackgroundColor:[NSColor redColor]];
}

@end
