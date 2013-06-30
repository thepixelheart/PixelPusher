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

#import "PHKinectServer.h"

#include <pthread.h>
#include <libfreenect/libfreenect.h>

void depth_cb(freenect_device *dev, void *v_depth, uint32_t timestamp);
void rgb_cb(freenect_device *dev, void *rgb, uint32_t timestamp);

@interface PHKinectThread : NSThread
@end

@implementation PHKinectThread {
  freenect_context *f_ctx;
  freenect_device *f_dev;
  pthread_t freenect_thread;

  CGImageRef _colorImage;

@public

  uint16_t *depth_buffer;
  uint8_t *rgb_buffer;
  uint8_t *back_rgb_buffer;
}

- (void)dealloc {
  if (_colorImage) {
    CGImageRelease(_colorImage);
  }
  if (depth_buffer) {
    free(depth_buffer);
  }
  if (rgb_buffer) {
    free(rgb_buffer);
  }
}

- (BOOL)startListening {
	if (freenect_init(&f_ctx, NULL) < 0) {
		printf("freenect_init() failed\n");
		return NO;
	}

	freenect_set_log_level(f_ctx, FREENECT_LOG_DEBUG);
	freenect_select_subdevices(f_ctx, (freenect_device_flags)(FREENECT_DEVICE_CAMERA));

	int nr_devices = freenect_num_devices (f_ctx);

	if (nr_devices < 1) {
		freenect_shutdown(f_ctx);
		return NO;
	}

  // Always pick the first device.
	static const int kDeviceNumber = 0;
	if (freenect_open_device(f_ctx, &f_dev, kDeviceNumber) < 0) {
		printf("Could not open device\n");
		freenect_shutdown(f_ctx);
		return NO;
	}

  return YES;
}

- (void)doRunLoop {
	depth_buffer = (uint16_t*)malloc(640*480*sizeof(uint16_t));
  rgb_buffer = (uint8_t*)malloc(640 * 480 * sizeof(uint8_t) * 4);

  freenect_set_user(f_dev, (__bridge void *)(self));
  freenect_set_depth_callback(f_dev, depth_cb);
	freenect_set_video_callback(f_dev, rgb_cb);
	freenect_set_video_mode(f_dev, freenect_find_video_mode(FREENECT_RESOLUTION_MEDIUM, FREENECT_VIDEO_RGB));
	freenect_set_depth_mode(f_dev, freenect_find_depth_mode(FREENECT_RESOLUTION_MEDIUM, FREENECT_DEPTH_REGISTERED));
	freenect_set_video_buffer(f_dev, back_rgb_buffer);

	freenect_start_depth(f_dev);
	freenect_start_video(f_dev);

	while (1) {
		int res = freenect_process_events(f_ctx);
		if (res < 0 && res != -10) {
			printf("\nError %d received from libusb - aborting.\n",res);
			break;
		}
	}

	freenect_stop_depth(f_dev);
	freenect_stop_video(f_dev);

	freenect_close_device(f_dev);
	freenect_shutdown(f_ctx);
}

- (void)depthMapDidChange {
}

- (void)colorMapDidChange {
  const size_t kComponentsPerPixel = 4;
  const size_t kBitsPerComponent = 8;
  static const size_t kBufferWidth = 640;
  static const size_t kBufferHeight = 480;
  static const size_t kBytesPerRow = ((kBitsPerComponent * kBufferWidth) / 8) * kComponentsPerPixel;
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef gtx = CGBitmapContextCreate(rgb_buffer, kBufferWidth, kBufferHeight, kBitsPerComponent, kBytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast);

  if (gtx) {
    @synchronized(self) {
      if (_colorImage) {
        CGImageRelease(_colorImage);
      }
      _colorImage = CGBitmapContextCreateImage(gtx);
    }
  }

  CGColorSpaceRelease(colorSpace);
  CGContextRelease(gtx);
}

- (CGImageRef)colorImage {
  CGImageRef colorImage = nil;
  @synchronized(self) {
    colorImage = CGImageRetain(_colorImage);
  }
  return colorImage;
}

- (void)main {
  if ([self startListening]) {
    [self doRunLoop];
  }
}

@end

@implementation PHKinectServer {
  PHKinectThread* _thread;
}

- (id)init {
  if ((self = [super init])) {
    _thread = [[PHKinectThread alloc] init];
    _thread.threadPriority = 0.7;
    [_thread start];
  }
  return self;
}

- (CGImageRef)colorImage {
  return [_thread colorImage];
}

@end

void depth_cb(freenect_device *dev, void *v_depth, uint32_t timestamp) {
  PHKinectThread* thread = (__bridge PHKinectThread *)freenect_get_user(dev);
  memcpy(thread->depth_buffer, v_depth, sizeof(uint16_t) * 640 * 480);
  [thread depthMapDidChange];
}

void rgb_cb(freenect_device *dev, void *rgb, uint32_t timestamp) {
  PHKinectThread* thread = (__bridge PHKinectThread *)freenect_get_user(dev);
	// swap buffers

  uint8_t* rgb_data = (uint8_t *)rgb;
  memset(thread->rgb_buffer, 255, 640*480*4);
	for (int i = 0; i < 640*480; i++) {
    thread->rgb_buffer[4 * i + 0] = rgb_data[3 * i + 0];
    thread->rgb_buffer[4 * i + 1] = rgb_data[3 * i + 1];
    thread->rgb_buffer[4 * i + 2] = rgb_data[3 * i + 2];
  }
  [thread colorMapDidChange];
}
