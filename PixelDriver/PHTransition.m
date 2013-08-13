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

#import "PHTransition.h"

#import "PHCrossFadeTransition.h"
#import "PHMidCrossFadeTransition.h"
#import "PHStarWarsTransition.h"
#import "PHShutterTransition.h"
#import "PHNoiseTransition.h"
#import "PHFlashTransition.h"
#import "PHHolesTransition.h"
#import "PHBarsSwipeTransition.h"

@implementation PHTransition

+ (id)transition {
  return [[self alloc] init];
}

- (id)copyWithZone:(NSZone *)zone {
  return [[self.class allocWithZone:zone] init];
}

- (void)renderBitmapInContext:(CGContextRef)cx
                         size:(CGSize)size
                  leftContext:(CGContextRef)leftContext
                 rightContext:(CGContextRef)rightContext
                            t:(CGFloat)t {
  // No-op
}

- (NSString *)tooltipName {
  return NSStringFromClass([self class]);
}

+ (NSArray *)allTransitions {
  return @[
    [PHMidCrossFadeTransition transition],
    [PHCrossFadeTransition transition],
    [PHStarWarsTransition transition],
    [PHShutterTransition transition],
    [PHNoiseTransition transition],
    [PHFlashTransition transition],
    [PHHolesTransition transition],
    [PHBarsSwipeTransition transition],
  ];
}

@end
