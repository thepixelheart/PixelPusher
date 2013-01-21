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

#import "PHButton.h"

@interface PHButtonCell : NSButtonCell
@end

@implementation PHButtonCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
}

- (NSDictionary *)textAttributes {
  NSShadow* shadow = [[NSShadow alloc] init];
  shadow.shadowOffset = CGSizeMake(0, 1);
  shadow.shadowColor = [NSColor blackColor];
  return @{
    NSForegroundColorAttributeName:[NSColor colorWithDeviceWhite:1 alpha:1],
    NSFontAttributeName:[NSFont boldSystemFontOfSize:10],
    NSShadowAttributeName:shadow
  };
}

- (void)drawBezelWithFrame:(NSRect)frame
                    inView:(NSView *)controlView {
  // http://www.amateurinmotion.com/articles/2010/05/06/drawing-custom-nsbutton-in-cocoa.html
  NSGraphicsContext *ctx = [NSGraphicsContext currentContext];

  CGFloat roundedRadius = 2.0f;

  // Outer stroke (drawn as gradient)

  [ctx saveGraphicsState];
  NSBezierPath *outerClip = [NSBezierPath bezierPathWithRoundedRect:frame
                                                            xRadius:roundedRadius
                                                            yRadius:roundedRadius];
  [outerClip setClip];

  NSGradient *outerGradient = [[NSGradient alloc] initWithColorsAndLocations:
                               [NSColor colorWithDeviceWhite:0.20f alpha:1.0f], 0.0f,
                               [NSColor colorWithDeviceWhite:0.21f alpha:1.0f], 1.0f,
                               nil];

  [outerGradient drawInRect:[outerClip bounds] angle:90.0f];
  [ctx restoreGraphicsState];

  // Background gradient

  [ctx saveGraphicsState];
  NSBezierPath *backgroundPath =
  [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(frame, 1.0f, 1.0f)
                                  xRadius:roundedRadius
                                  yRadius:roundedRadius];
  [backgroundPath setClip];

  NSGradient *backgroundGradient = [[NSGradient alloc] initWithColorsAndLocations:
                                    [NSColor colorWithDeviceWhite:0.17f alpha:1.0f], 0.0f,
                                    [NSColor colorWithDeviceWhite:0.20f alpha:1.0f], 0.12f,
                                    [NSColor colorWithDeviceWhite:0.27f alpha:1.0f], 0.5f,
                                    [NSColor colorWithDeviceWhite:0.30f alpha:1.0f], 0.5f,
                                    [NSColor colorWithDeviceWhite:0.42f alpha:1.0f], 0.98f,
                                    [NSColor colorWithDeviceWhite:0.50f alpha:1.0f], 1.0f,
                                    nil];

  [backgroundGradient drawInRect:[backgroundPath bounds] angle:270.0f];
  [ctx restoreGraphicsState];

  // Dark stroke

  [ctx saveGraphicsState];
  [[NSColor colorWithDeviceWhite:0.12f alpha:1.0f] setStroke];
  [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(frame, 0.75f, 0.75f)
                                   xRadius:roundedRadius
                                   yRadius:roundedRadius] stroke];
  [ctx restoreGraphicsState];

  // Inner light stroke

  [ctx saveGraphicsState];
  [[NSColor colorWithDeviceWhite:1.0f alpha:0.05f] setStroke];
  [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(frame, 1.25f, 1.25f)
                                   xRadius:roundedRadius
                                   yRadius:roundedRadius] stroke];
  [ctx restoreGraphicsState];

  // Draw darker overlay if button is pressed

  if([self isHighlighted]) {
    [ctx saveGraphicsState];
    [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(frame, 1.0f, 1.0f)
                                     xRadius:roundedRadius
                                     yRadius:roundedRadius] setClip];
    [[NSColor colorWithCalibratedWhite:0.0f alpha:0.35] setFill];
    NSRectFillUsingOperation(frame, NSCompositeSourceOver);
    [ctx restoreGraphicsState];
  }

  NSMutableAttributedString* string = [[NSMutableAttributedString alloc] initWithString:self.title attributes:[self textAttributes]];
  [string setAlignment:NSCenterTextAlignment range:NSMakeRange(0, string.length)];
  [string drawInRect:CGRectInset(frame, 5, 6)];
}

@end

@implementation PHButton

+ (void)initialize {
  [PHButton setCellClass:[PHButtonCell class]];
}

- (void)sizeToFit {
  [super sizeToFit];
  self.frame = CGRectInset(self.frame, -2, -2);
}

@end
