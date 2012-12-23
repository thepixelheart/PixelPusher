PixelDriver
===========

The Pixel Heart Driver

Getting Started
---------------

You'll need Xcode to build and run the Pixel Driver.

https://itunes.apple.com/us/app/xcode/id497799835?mt=12

### 1. Check out the submodules by running the following:

```
git submodule init
git submodule update
```

### 2. Install the D2XX libraries by running the following:

```
cd D2XX
sudo bash install.sh
```

D2XX is a library we use to interface with the PixelHeart. You'll need these to be able to link the
PixelDriver application correctly.

### 3. Install SoundFlower by running the installer in the soundflower/ folder.

This will allow you to route sound through the driver.

### 4. Routing sound through the driver

#### System audio

- To route system audio through the driver you have to open the System Preferences and click the Sound
  configuration.
- Select the "Output" tab.
- Select the Soundflower (2ch) output.
- Make sure the volume is max (you can control the volume via the PixelDriver).

#### Specific application routing

- Some applications have specific audio routing capabilities. Use the Soundflower (2ch) output similar to
  above to route their audio to the PixelDriver.

#### Listening to audio in the PixelDriver

[![](https://raw.github.com/ThePixelHeart/PixelDriver/master/pixeldriverinfopanel.png)](https://raw.github.com/ThePixelHeart/PixelDriver/master/pixeldriverinfopanel.png)

- Once your audio is being sent through Soundflower, run the PixelDriver.
- Select "Soundflower (2ch)" in the top dropdown box of the info page.
- Select "Built-in Output" to have the audio play through your speakers.
- Click the "Start Listening" button and then adjust the audio levels accordingly.

Writing Animations
------------------

Start by creating an animation class:

```obj-c
#import "PHAnimation.h"

@interface PHBasicSpectrumAnimation : PHAnimation
@end
```

```obj-c
#import "PHBasicSpectrumAnimation.h"

@implementation PHBasicSpectrumAnimation {
  PHDegrader* _bassDegrader;
}

- (id)init {
  if ((self = [super init])) {
    _bassDegrader = [[PHDegrader alloc] init];
  }
  return self;
}

- (void)renderBitmapInContext:(CGContextRef)cx size:(CGSize)size {
  if (self.driver.spectrum) {
    [_bassDegrader tickWithPeak:self.driver.subBassAmplitude];

    CGContextSetRGBFillColor(cx, 1, 0, 0, 1);
    CGContextFillRect(cx, CGRectMake(0, 0, _bassDegrader.value * size.width, kWallHeight));
  }
}

@end
```

Next open PHAnimation.m in the Animations folder and add your new class to the
list of animations returned by allAnimations.

You'll also need to import the class header at the top of the PHAnimation.m
file.

```obj-c
#import "PHBasicSpectrumAnimation.h"
````


Using the Launchpad
===================

The launchpad is the input mechanism that controls all animations on the Pixel Heart.

Default Mode
------------

[![](https://raw.github.com/ThePixelHeart/PixelDriver/master/launchpad.png)](https://raw.github.com/ThePixelHeart/PixelDriver/master/launchpad.png)

This mode allows you to switch between animations with a single tap of any animation button.

By default animations will transition with a one second cross-fade. If you want the transition
to be instant you can tap the "inst" button (5th button in on the top row) to enable instant
transitions. Tapping this button again will turn off instant transitions.

When you tap an animation to transition to it, the previous animation's button will flash until
the transition has completed. You can not start another transition while this is happening.

Preview Mode
------------

[![](https://raw.github.com/ThePixelHeart/PixelDriver/master/launchpad_previewmode.png)](https://raw.github.com/ThePixelHeart/PixelDriver/master/launchpad_previewmode.png)

Preview mode allows you to preview animations before showing them on the Pixel Heart. To enter
Preview mode, tap the "arm" button (the bottom right button). This will enter Preview mode and
the light will change to green to reflect this fact.

When in preview mode, tapping an animation will instantly show it in the Pixel Driver's preview
window.

The currently playing animation's button is green.

The currently previewing animation's button is yellow.

If the currently previewing animation is the playing animation, then the corresponding button will
be red.

To transition to an animation while in preview mode, double tap any animation button. This will
queue a transition similar to the Default Mode (the instant button is respected, for example).
