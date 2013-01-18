//
//  PHBassShooterAnimation.m
//  PixelDriver
//
//  Created by Anton on 12/31/12.
//  Copyright (c) 2012 Pixel Heart. All rights reserved.
//

#import "PHBassShooterAnimation.h"
#include <stdlib.h>
#import "Utilities.h"

static const int kMaxSprites = 50;
static const int kMaxAddPerFrame = 1;
static const int kSpriteLivetime = 200;
static const int kDecaySpeed = 5;
static const int kMaxRadius = 10;
static const int kMinRaidus = 2;

@interface PHSprite : NSObject
@end

@implementation PHSprite {
    CGPoint _position;
    NSColor* _color;
    int _age;
    int _radius;
}

- (id)initWithPosition:(CGPoint)position {
    if ((self = [super init])) {
        _position = position;
        _color = generateRandomColor();
        _age = kSpriteLivetime;
        _radius = kMinRaidus + arc4random_uniform(kMaxRadius);
    }
    return self;
}

- (void)tickWithSpeedMultiplier:(CGFloat)speedMultiplier {
    _age -= 1 + speedMultiplier * kDecaySpeed;
}

- (void)renderInContext:(CGContextRef)cx size:(CGSize)size {
    // project the rect on the screen
    CGContextSetRGBFillColor(cx, [_color redComponent], [_color greenComponent], [_color blueComponent], _age * 1.0 / kSpriteLivetime);
    CGContextFillEllipseInRect(cx, CGRectMake(_position.x - _radius, _position.y - _radius, _radius * 2, _radius * 2));
}

-(BOOL)isAlive {
    if (_age < 0) {
        return NO;
    }
    return YES;
}

@end

@implementation PHBassShooterAnimation {
    NSMutableArray *_sprites;
}

- (id)init {
    if ((self = [super init])) {
        _sprites = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  // remove invisible saws
  NSMutableArray *invisibleSprites = [NSMutableArray array];
  for(PHSprite* sp in _sprites) {
    if (![sp isAlive]) {
      [invisibleSprites addObject:sp];
    }
  }
  [_sprites removeObjectsInArray:invisibleSprites];


  if (self.vocalDegrader.value > 0.5) {
    for (int i = 0; (i < kMaxAddPerFrame) && ([_sprites count] < kMaxSprites); ++i) {
      PHSprite* sp = [[PHSprite alloc] initWithPosition:CGPointMake(arc4random_uniform(size.width), arc4random_uniform(size.height))];
      [_sprites addObject:sp];
    }
  }
  // tick and render the rects;

  for(PHSprite* sp in _sprites) {
    [sp tickWithSpeedMultiplier: self.bassDegrader.value];
    [sp renderInContext:cx size:size];
  }
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  for (int i = 0; ([_sprites count] < 20); ++i) {
    PHSprite* sp = [[PHSprite alloc] initWithPosition:CGPointMake(arc4random_uniform(size.width), arc4random_uniform(size.height))];
    [_sprites addObject:sp];
  }
  [self renderBitmapInContext:cx size:size];
}

- (NSString *)tooltipName {
    return @"Bass Shooter";
}

- (NSArray *)categories {
  return @[
    PHAnimationCategoryShapes
  ];
}

@end
