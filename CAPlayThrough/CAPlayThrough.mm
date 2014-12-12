#include "CAPlayThroughInternal.h"

#import <Cocoa/Cocoa.h>

#import "CAPlayThroughObjc.h"

NSString* const kAudioBufferNotification = @"kAudioBufferNotification";
NSString* const kAudioBufferKey = @"buffer";
NSString* const kAudioBufferSizeKey = @"bufferSize";
NSString* const kAudioNumberOfChannelsKey = @"numberOfChannels";

void CAPlayThrough::postNotification(float **buffer, UInt32 bufferSize) {
  UInt32 numberOfChannels = this->mInputDevice.mFormat.mChannelsPerFrame;

  NSDictionary *userInfo = @{kAudioBufferKey:[NSValue valueWithPointer:buffer],
                             kAudioBufferSizeKey:@(bufferSize),
                             kAudioNumberOfChannelsKey:@(numberOfChannels)};

  [[NSNotificationCenter defaultCenter] postNotificationName:kAudioBufferNotification object:nil userInfo:userInfo];
}
