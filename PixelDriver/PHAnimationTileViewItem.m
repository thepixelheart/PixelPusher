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

#import "PHAnimationTileViewItem.h"

#import "PHAnimationTileView.h"

@implementation PHAnimationTileViewItem

- (void)loadView {
  [self setView:[[PHAnimationTileView alloc] initWithFrame:NSZeroRect]];
}

- (void)setRepresentedObject:(id)representedObject {
  [super setRepresentedObject:representedObject];

  PHAnimationTileView* view = (PHAnimationTileView *)self.view;
  view.item = representedObject;
  [view setNeedsDisplay:YES];
}

- (void)setSelected:(BOOL)selected {
  [super setSelected:selected];

  PHAnimationTileView* view = (PHAnimationTileView *)self.view;
  [view setSelected:selected];
  [view setNeedsDisplay:YES];
}

@end
