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

uint16_t t_gamma[10000];
void depth_cb(freenect_device *dev, void *v_depth, uint32_t timestamp);
void rgb_cb(freenect_device *dev, void *rgb, uint32_t timestamp);

@interface PHKinectThread : NSThread
@end

@implementation PHKinectThread {
  freenect_context *f_ctx;
  freenect_device *f_dev;
  pthread_t freenect_thread;

  CGImageRef _colorImage;
  CGImageRef _depthImage;

@public

  uint8_t *depth_buffer;
  uint8_t *rgb_buffer;
}

- (void)dealloc {
  if (_colorImage) {
    CGImageRelease(_colorImage);
  }
  if (_depthImage) {
    CGImageRelease(_depthImage);
  }
  if (depth_buffer) {
    free(depth_buffer);
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
	depth_buffer = (uint8_t*)malloc(640*480*4);

  freenect_set_user(f_dev, (__bridge void *)(self));
  freenect_set_depth_callback(f_dev, depth_cb);
	freenect_set_video_callback(f_dev, rgb_cb);
	freenect_set_video_mode(f_dev, freenect_find_video_mode(FREENECT_RESOLUTION_MEDIUM, FREENECT_VIDEO_RGB));
	freenect_set_depth_mode(f_dev, freenect_find_depth_mode(FREENECT_RESOLUTION_MEDIUM, FREENECT_DEPTH_REGISTERED));
	freenect_set_video_buffer(f_dev, rgb_buffer);

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
  const size_t kComponentsPerPixel = 4;
  const size_t kBitsPerComponent = 8;
  static const size_t kBufferWidth = 640;
  static const size_t kBufferHeight = 480;
  static const size_t kBytesPerRow = ((kBitsPerComponent * kBufferWidth) / 8) * kComponentsPerPixel;
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef gtx = CGBitmapContextCreate(depth_buffer, kBufferWidth, kBufferHeight, kBitsPerComponent, kBytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast);

  @synchronized(self) {
    if (_colorImage) {
      CGImageRelease(_colorImage);
    }
    _colorImage = CGBitmapContextCreateImage(gtx);
  }

  CGColorSpaceRelease(colorSpace);
  CGContextRelease(gtx);
}

- (void)colorMapDidChange {
  const size_t kComponentsPerPixel = 4;
  const size_t kBitsPerComponent = 8;
  static const size_t kBufferWidth = 640;
  static const size_t kBufferHeight = 480;
  static const size_t kBytesPerRow = ((kBitsPerComponent * kBufferWidth) / 8) * kComponentsPerPixel;
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef gtx = CGBitmapContextCreate(depth_buffer, kBufferWidth, kBufferHeight, kBitsPerComponent, kBytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast);

  @synchronized(self) {
    if (_depthImage) {
      CGImageRelease(_depthImage);
    }
    _depthImage = CGBitmapContextCreateImage(gtx);
  }

  CGColorSpaceRelease(colorSpace);
  CGContextRelease(gtx);
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

+ (void)initialize {
	int i;
	for (i=0; i<10000; i++) {
		float v = i/2048.0;
		v = powf(v, 3)* 6;
		t_gamma[i] = v*6*256;
	}
}

- (id)init {
  if ((self = [super init])) {
    _thread = [[PHKinectThread alloc] init];
    _thread.threadPriority = 0.7;
    [_thread start];
  }
  return self;
}

@end

void depth_cb(freenect_device *dev, void *v_depth, uint32_t timestamp) {
  PHKinectThread* thread = (__bridge PHKinectThread *)freenect_get_user(dev);
	int i;
	uint16_t *depth = (uint16_t*)v_depth;

	for (i = 0; i < 640*480; i++) {
		//if (depth[i] >= 2048) continue;
		int pval = t_gamma[depth[i]] / 4;
		int lb = pval & 0xff;
		thread->depth_buffer[4*i+3] = 128; // default alpha value
		if (depth[i] ==  0) thread->depth_buffer[4*i+3] = 0; // remove anything without depth value
		switch (pval>>8) {
			case 0:
				thread->depth_buffer[4*i+0] = 255;
				thread->depth_buffer[4*i+1] = 255-lb;
				thread->depth_buffer[4*i+2] = 255-lb;
				break;
			case 1:
				thread->depth_buffer[4*i+0] = 255;
				thread->depth_buffer[4*i+1] = lb;
				thread->depth_buffer[4*i+2] = 0;
				break;
			case 2:
				thread->depth_buffer[4*i+0] = 255-lb;
				thread->depth_buffer[4*i+1] = 255;
				thread->depth_buffer[4*i+2] = 0;
				break;
			case 3:
				thread->depth_buffer[4*i+0] = 0;
				thread->depth_buffer[4*i+1] = 255;
				thread->depth_buffer[4*i+2] = lb;
				break;
			case 4:
				thread->depth_buffer[4*i+0] = 0;
				thread->depth_buffer[4*i+1] = 255-lb;
				thread->depth_buffer[4*i+2] = 255;
				break;
			case 5:
				thread->depth_buffer[4*i+0] = 0;
				thread->depth_buffer[4*i+1] = 0;
				thread->depth_buffer[4*i+2] = 255-lb;
				break;
			default:
				thread->depth_buffer[4*i+0] = 0;
				thread->depth_buffer[4*i+1] = 0;
				thread->depth_buffer[4*i+2] = 0;
				thread->depth_buffer[4*i+3] = 0;
				break;
		}
	}
  [thread depthMapDidChange];
}

void rgb_cb(freenect_device *dev, void *rgb, uint32_t timestamp) {
  PHKinectThread* thread = (__bridge PHKinectThread *)freenect_get_user(dev);
	// swap buffers
  thread->rgb_buffer = rgb;
  [thread colorMapDidChange];
}
