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

#import <Cocoa/Cocoa.h>

@class PHSpectrumAnalyzerView;
@class PHWaveFormView;

@interface PHInfoPanel : NSPanel

@property (nonatomic, strong) IBOutlet PHSpectrumAnalyzerView* leftSpectrumView;
@property (nonatomic, strong) IBOutlet PHSpectrumAnalyzerView* rightSpectrumView;
@property (nonatomic, strong) IBOutlet PHSpectrumAnalyzerView* unifiedSpectrumView;
@property (nonatomic, strong) IBOutlet PHWaveFormView* leftWaveView;
@property (nonatomic, strong) IBOutlet PHWaveFormView* rightWaveView;
@property (nonatomic, strong) IBOutlet PHWaveFormView* unifiedWaveView;
@property (nonatomic, strong) IBOutlet NSPopUpButton* audioRecordingButton;
@property (nonatomic, strong) IBOutlet NSPopUpButton* audioOutputButton;
@property (nonatomic, strong) IBOutlet NSSlider* volumeSlider;
@property (nonatomic, strong) IBOutlet NSButton* listeningButton;

@end
