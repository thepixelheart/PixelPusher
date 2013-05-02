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

#import "PHFoldersPrefsPage.h"

#import "AppDelegate.h"
#import "PHSystem.h"

typedef enum {
  PHFolderPrefIdGifs,
  PHFolderPrefIdScreenshots,
  PHFolderPrefIdComposites,
  PHFolderPrefIdResetComposites,
} PHFolderPrefId;

@implementation PHFoldersPrefsPage

- (id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    [self addRowWithLabel:@"Gifs Folder" buttonId:PHFolderPrefIdGifs];
    [self addRowWithLabel:@"Screenshots Folder" buttonId:PHFolderPrefIdScreenshots];
    [self addRowWithLabel:@"Composites File" buttonId:PHFolderPrefIdComposites];
    [self addRowWithLabel:@"Reset Composites" buttonId:PHFolderPrefIdResetComposites];
  }
  return self;
}

- (NSString *)titleForButtonId:(NSInteger)buttonId {
  if (buttonId == PHFolderPrefIdGifs
      || buttonId == PHFolderPrefIdScreenshots
      || buttonId == PHFolderPrefIdComposites) {
    return @"Open in Finder";

  } else if (buttonId == PHFolderPrefIdResetComposites) {
    return @"Reset";

  } else {
    return nil;
  }
}

- (void)didTapButton:(NSButton *)button {
  if (button.tag == PHFolderPrefIdGifs) {
    NSArray *fileURLs = [NSArray arrayWithObjects:[NSURL fileURLWithPath:[PHSys() pathForUserGifs]], nil];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:fileURLs];

  } else if (button.tag == PHFolderPrefIdScreenshots) {
    NSArray *fileURLs = [NSArray arrayWithObjects:[NSURL fileURLWithPath:[PHSys() pathForScreenshots]], nil];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:fileURLs];

  } else if (button.tag == PHFolderPrefIdComposites) {
    NSArray *fileURLs = [NSArray arrayWithObjects:[NSURL fileURLWithPath:[PHSys() pathForCompositeFile]], nil];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:fileURLs];

  } else if (button.tag == PHFolderPrefIdResetComposites) {
    NSString* compositeFile = [PHSys() pathForCompositeFile];
    NSFileManager* fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:compositeFile]) {
      [fm moveItemAtPath:compositeFile
                  toPath:[compositeFile stringByAppendingFormat:@"%f", [NSDate timeIntervalSinceReferenceDate]]
                   error:nil];
    }
    NSString* latestCompositesPath = PHFilenameForResourcePath(@"composites-latest.plist");
    [fm copyItemAtPath:latestCompositesPath toPath:compositeFile error:nil];

    [PHSys() loadComposites];
  }
  [super didTapButton:button];
}

@end
