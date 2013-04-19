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

#import "PHLaunchpadDemoAnimation.h"

static const NSInteger kNumberOfLaunchpadCols = 8;
static const NSInteger kNumberOfLaunchpadRows = 8;

@interface PHLaunchpadValues : NSObject
@property (nonatomic, strong) PHDegrader* intensity;
@property (nonatomic, assign) CGFloat rotationOffset;
@end

@implementation PHLaunchpadValues

- (id)init {
  if ((self = [super init])) {
    _intensity = [[PHDegrader alloc] init];
  }
  return self;
}
@end

@implementation PHLaunchpadDemoAnimation {
  NSArray* _launchpadValues;
  CGFloat _colorAdvance;
}

- (id)init {
  if ((self = [super init])) {
    NSMutableArray* values = [NSMutableArray array];
    for (NSInteger ix = 0; ix < kNumberOfLaunchpadRows * kNumberOfLaunchpadCols; ++ix) {
      PHLaunchpadValues* value = [[PHLaunchpadValues alloc] init];
      [values addObject:value];
    }
    _launchpadValues = values;
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  CGContextSaveGState(cx);

  CGContextSetBlendMode(cx, kCGBlendModeColor);
  
  for (NSInteger iy = 0; iy < kNumberOfLaunchpadRows; ++iy) {
    for (NSInteger ix = 0; ix < kNumberOfLaunchpadCols; ++ix) {
      PHLaunchpadValues* value = _launchpadValues[ix + iy * kNumberOfLaunchpadCols];
      BOOL isPressed = [self.animationTick.hardwareState wasLaunchpadButtonPressedAtX:ix y:iy];
      CGFloat peak = isPressed ? 1 : 0;
      [value.intensity tickWithPeak:peak];
      if (isPressed) {
        value.rotationOffset = ((CGFloat)arc4random_uniform(1000) / 1000.0 - 0.5) * 5;
      }
    }
  }

  CGFloat colWidth = size.width / (CGFloat)kNumberOfLaunchpadCols;
  CGFloat rowHeight = size.height / (CGFloat)kNumberOfLaunchpadRows;

  CGRect squareFrame = CGRectMake(-colWidth / 2, -rowHeight / 2, colWidth, rowHeight);
  for (NSInteger iy = 0; iy < kNumberOfLaunchpadRows; ++iy) {
    for (NSInteger ix = 0; ix < kNumberOfLaunchpadCols; ++ix) {
      CGContextSaveGState(cx);
      PHLaunchpadValues* value = _launchpadValues[ix + iy * kNumberOfLaunchpadCols];

      CGFloat offset = ix + iy * kNumberOfLaunchpadCols;
      CGFloat red = sin(offset) * 0.5 + 0.5;
      CGFloat green = cos(offset * 5 + M_PI_2) * 0.5 + 0.5;
      CGFloat blue = sin(offset * 13 - M_PI_4) * 0.5 + 0.5;
      CGContextSetFillColorWithColor(cx, [NSColor colorWithDeviceRed:red green:green blue:blue alpha:value.intensity.value].CGColor);

      CGContextTranslateCTM(cx, (CGFloat)ix * colWidth + colWidth / 2, (CGFloat)iy * rowHeight + rowHeight / 2);
      CGContextRotateCTM(cx, value.intensity.value + value.rotationOffset);
      CGContextScaleCTM(cx, 1 + value.intensity.value * 8, 1 + value.intensity.value * 8);

      CGContextTranslateCTM(cx, -colWidth / 2, -rowHeight / 2);
      CGContextBeginPath(cx);

      CGSize heartSize = CGSizeMake(colWidth, rowHeight);
      CGPoint midPoint = CGPointMake(heartSize.width / 2, heartSize.height / 2);
      CGContextMoveToPoint(cx, midPoint.x, midPoint.y + heartSize.height / 8);
      CGFloat widthFactor = 4;
      CGContextAddCurveToPoint(cx,
                               midPoint.x, midPoint.y + heartSize.height / 2.5,
                               midPoint.x - heartSize.width / widthFactor, midPoint.y + heartSize.height / 2.5,
                               midPoint.x - heartSize.width / widthFactor, midPoint.y + heartSize.height / 8);
      CGContextAddCurveToPoint(cx,
                               midPoint.x - heartSize.width / widthFactor, midPoint.y - heartSize.height / 6,
                               midPoint.x, midPoint.y - heartSize.height / 6,
                               midPoint.x, midPoint.y - heartSize.height / 2.5);
      CGContextAddCurveToPoint(cx,
                               midPoint.x, midPoint.y - heartSize.height / 6,
                               midPoint.x + heartSize.width / widthFactor, midPoint.y - heartSize.height / 6,
                               midPoint.x + heartSize.width / widthFactor, midPoint.y + heartSize.height / 8);
      CGContextAddCurveToPoint(cx,
                               midPoint.x + heartSize.width / widthFactor, midPoint.y + heartSize.height / 2.5,
                               midPoint.x, midPoint.y + heartSize.height / 2.5,
                               midPoint.x, midPoint.y + heartSize.height / 8);
      CGContextClosePath(cx);
      CGContextClip(cx);

      CGContextTranslateCTM(cx, colWidth / 2, rowHeight / 2);

      CGContextFillRect(cx, squareFrame);
      CGContextRestoreGState(cx);
    }
  }
  
  CGContextRestoreGState(cx);
}

- (NSImage *)previewImage {
  return [NSImage imageNamed:@"launchpad"];
}

- (NSString *)tooltipName {
  return @"Launchpad";
}

- (NSArray *)categories {
  return @[];
}

@end
