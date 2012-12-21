PixelDriver
===========

The Pixel Heart Driver

Getting Started
---------------

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

Next open the PHWallView class and find the line where `_animation` is being set. Change the class that's
being instantiated to the one you've just created.

```obj-c
_animation = [[PHBasicSpectrumAnimation alloc] init];
```

You also need to import the class header.

```obj-c
#import "PHBasicSpectrumAnimation.h"
````
