//
//  PHMovingSawAnimation.m
//  PixelDriver
//
//  Created by Anton on 12/30/12.
//  Copyright (c) 2012 Pixel Heart. All rights reserved.
//

#import "PHMovingSawAnimation.h"
#include <stdlib.h>
#import "Utilities.h"

static const int kSawWidth = 6;
static const int kSpeed = 1;

@interface PHSaw : NSObject
@end

@implementation PHSaw {
    long _position;
    NSColor* _color;
}

- (id)initWithPosition:(long)position {
    if ((self = [super init])) {
        _position = position;
        _color = generateRandomColor();
    }
    return self;
}

- (void)tickWithSpeedMultiplier:(CGFloat)speedMultiplier {
    _position += speedMultiplier * kSpeed;
}

- (void)renderInContext:(CGContextRef)cx size:(CGSize)size {
    // project the rect on the screen
    CGContextSetRGBFillColor(cx, [_color redComponent], [_color greenComponent], [_color blueComponent], 1);
    CGMutablePathRef pathRef = CGPathCreateMutable();
    
    /* do something with pathRef. For example:*/
    CGPathMoveToPoint(pathRef, NULL, - 2 + _position, size.height + 14);
    CGPathAddLineToPoint(pathRef, NULL, -2 + _position + size.height, -14);
    CGPathAddLineToPoint(pathRef, NULL, _position + size.height + kSawWidth + 2, -14);
    CGPathAddLineToPoint(pathRef, NULL, _position + kSawWidth + 2, size.height + 14);
    
    CGPathCloseSubpath(pathRef);
    
    CGContextAddPath(cx, pathRef);
    CGPathRelease(pathRef);
    CGContextFillPath(cx);
}

-(BOOL)isVisible:(CGSize)size {
    if (_position > kWallWidth) {
        return NO;
    }
    return YES;
}

@end

@implementation PHMovingSawAnimation {
    NSMutableArray *_saws;
}

- (id)init {
    if ((self = [super init])) {
        _saws = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  // remove invisible saws
  NSMutableArray *invisibleSaws = [NSMutableArray array];
  for(PHSaw* saw in _saws) {
      if (![saw isVisible:size]) {
          [invisibleSaws addObject:saw];
      }
  }
  [_saws removeObjectsInArray:invisibleSaws];
  
  
  if ([_saws count] < (size.width + size.height + kSawWidth) / kSawWidth) {
      int addN = (size.width + size.height + kSawWidth) / kSawWidth - [_saws count];
      for (int i = 0; i < addN; ++i) {
          PHSaw* saw = [[PHSaw alloc] initWithPosition:i * kSawWidth - size.height - kSawWidth];
          [_saws addObject:saw];
      }
  }
  // tick and render the rects;
  
  for(PHSaw* saw in _saws) {
          [saw tickWithSpeedMultiplier: 1];
      [saw renderInContext:cx size:size];
  }
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  [self renderBitmapInContext:cx size:size];
}

- (NSString *)tooltipName {
    return @"Moving Saw";
}

- (NSArray *)categories {
  return @[
    PHAnimationCategoryShapes
  ];
}

@end
