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

#import "PHScriptAnimation.h"

#import "PHScript.h"
#import <FScript/FScript.h>

@implementation PHScriptAnimation

+ (id)animationWithScript:(PHScript *)script {
  PHScriptAnimation* animation = [PHScriptAnimation animation];
  animation.script = script;
  return animation;
}

- (id)copyWithZone:(NSZone *)zone {
  PHScriptAnimation* animation = [[self.class allocWithZone:zone] init];
  animation.script = self.script;
  return animation;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  [_script.interpreter setObject:@(size.width) forIdentifier:@"kWallWidth"];
  [_script.interpreter setObject:@(size.height) forIdentifier:@"kWallHeight"];
  [_script.interpreter setObject:self.bassDegrader forIdentifier:@"bassDegrader"];
  [_script.interpreter setObject:self.hihatDegrader forIdentifier:@"hihatDegrader"];
  [_script.interpreter setObject:self.vocalDegrader forIdentifier:@"vocalDegrader"];
  [_script.interpreter setObject:self.snareDegrader forIdentifier:@"snareDegrader"];
  [_script.interpreter setObject:[NSNumber numberWithDouble:self.secondsSinceLastTick]
                   forIdentifier:@"secondsSinceLastTick"];
  [_script renderBitmapInContext:cx size:size];
}

- (void)renderPreviewInContext:(CGContextRef)cx size:(CGSize)size {
  [self renderBitmapInContext:cx size:size];
}

- (NSString *)tooltipName {
  return [_script.sourceFile lastPathComponent];
}

- (NSArray *)categories {
  return @[PHAnimationCategoryScripts];
}

@end
