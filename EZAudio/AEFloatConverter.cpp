//
//  AEFloatConverter.m
//  The Amazing Audio Engine
//
//  Created by Michael Tyson on 25/10/2012.
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import "AEFloatConverter.h"

#define checkResult(result,operation) (_checkResult((result),(operation),strrchr(__FILE__, '/')+1,__LINE__))
static inline bool _checkResult(OSStatus result, const char *operation, const char* file, int line) {
  if ( result != noErr ) {
    printf("%s:%d: %s result %d %08X %4.4s", file, line, operation, (int)result, (int)result, (char*)&result);
    return false;
  }
  return true;
}

#define                        kNoMoreDataErr                            -2222

struct complexInputDataProc_t {
  AudioBufferList *sourceBuffer;
};

static OSStatus complexInputDataProc(AudioConverterRef             inAudioConverter,
                                     UInt32                        *ioNumberDataPackets,
                                     AudioBufferList               *ioData,
                                     AudioStreamPacketDescription  **outDataPacketDescription,
                                     void                          *inUserData);

AEFloatConverter::AEFloatConverter(AudioStreamBasicDescription sourceFormat) {
  _floatAudioDescription.mFormatID          = kAudioFormatLinearPCM;
  _floatAudioDescription.mFormatFlags       = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved;
  _floatAudioDescription.mChannelsPerFrame  = sourceFormat.mChannelsPerFrame;
  _floatAudioDescription.mBytesPerPacket    = sizeof(float);
  _floatAudioDescription.mFramesPerPacket   = 1;
  _floatAudioDescription.mBytesPerFrame     = sizeof(float);
  _floatAudioDescription.mBitsPerChannel    = 8 * sizeof(float);
  _floatAudioDescription.mSampleRate        = sourceFormat.mSampleRate;

  _sourceAudioDescription = sourceFormat;

  if ( memcmp(&sourceFormat, &_floatAudioDescription, sizeof(AudioStreamBasicDescription)) != 0 ) {
    checkResult(AudioConverterNew(&sourceFormat, &_floatAudioDescription, &_toFloatConverter), "AudioConverterNew");
    checkResult(AudioConverterNew(&_floatAudioDescription, &sourceFormat, &_fromFloatConverter), "AudioConverterNew");
    _scratchFloatBufferList = (AudioBufferList*)malloc(sizeof(AudioBufferList) + (_floatAudioDescription.mChannelsPerFrame-1)*sizeof(AudioBuffer));
    _scratchFloatBufferList->mNumberBuffers = _floatAudioDescription.mChannelsPerFrame;
    for ( int i=0; i<_scratchFloatBufferList->mNumberBuffers; i++ ) {
      _scratchFloatBufferList->mBuffers[i].mNumberChannels = 1;
    }
  }
}

AEFloatConverter::~AEFloatConverter() {
  if ( _toFloatConverter ) AudioConverterDispose(_toFloatConverter);
  if ( _fromFloatConverter ) AudioConverterDispose(_fromFloatConverter);
  if ( _scratchFloatBufferList ) free(_scratchFloatBufferList);
  //    [super dealloc];
}


bool AEFloatConverterToFloat(AEFloatConverter* THIS, AudioBufferList *sourceBuffer, float * const * targetBuffers, UInt32 frames) {
  if ( frames == 0 ) return true;

  if ( THIS->_toFloatConverter ) {
    UInt32 priorDataByteSize = sourceBuffer->mBuffers[0].mDataByteSize;
    for ( int i=0; i<sourceBuffer->mNumberBuffers; i++ ) {
      sourceBuffer->mBuffers[i].mDataByteSize = frames * THIS->_sourceAudioDescription.mBytesPerFrame;
    }

    for ( int i = 0; i < THIS->_scratchFloatBufferList->mNumberBuffers; i++ ) {
      THIS->_scratchFloatBufferList->mBuffers[i].mData = targetBuffers[i];
      THIS->_scratchFloatBufferList->mBuffers[i].mDataByteSize = frames * sizeof(float);
    }

    struct complexInputDataProc_t inputDataProc = { .sourceBuffer = sourceBuffer };
    OSStatus result = AudioConverterFillComplexBuffer(THIS->_toFloatConverter,
                                                      complexInputDataProc,
                                                      &inputDataProc,
                                                      &frames,
                                                      THIS->_scratchFloatBufferList,
                                                      NULL);

    for ( int i=0; i<sourceBuffer->mNumberBuffers; i++ ) {
      sourceBuffer->mBuffers[i].mDataByteSize = priorDataByteSize;
    }

    if ( !checkResult(result, "AudioConverterConvertComplexBuffer") ) {
      char message[5] = {0};
      *(UInt32*) message = CFSwapInt32HostToBig(result);
      printf("%s", message);
      return false;
    }

  } else {
    for ( int i=0; i<sourceBuffer->mNumberBuffers; i++ ) {
      memcpy(targetBuffers[i], sourceBuffer->mBuffers[i].mData, frames * sizeof(float));
    }
  }

  return true;
}

bool AEFloatConverterToFloatBufferList(AEFloatConverter* converter, AudioBufferList *sourceBuffer,  AudioBufferList *targetBuffer, UInt32 frames) {
  assert(targetBuffer->mNumberBuffers == converter->_floatAudioDescription.mChannelsPerFrame);

  float *targetBuffers[targetBuffer->mNumberBuffers];
  for ( int i=0; i<targetBuffer->mNumberBuffers; i++ ) {
    targetBuffers[i] = (float*)targetBuffer->mBuffers[i].mData;
  }
  return AEFloatConverterToFloat(converter, sourceBuffer, targetBuffers, frames);
}

bool AEFloatConverterFromFloat(AEFloatConverter* THIS, float * const * sourceBuffers, AudioBufferList *targetBuffer, UInt32 frames) {
  if ( frames == 0 ) return true;

  if ( THIS->_fromFloatConverter ) {
    for ( int i=0; i<THIS->_scratchFloatBufferList->mNumberBuffers; i++ ) {
      THIS->_scratchFloatBufferList->mBuffers[i].mData = sourceBuffers[i];
      THIS->_scratchFloatBufferList->mBuffers[i].mDataByteSize = frames * sizeof(float);
    }

    UInt32 priorDataByteSize = targetBuffer->mBuffers[0].mDataByteSize;
    for ( int i=0; i<targetBuffer->mNumberBuffers; i++ ) {
      targetBuffer->mBuffers[i].mDataByteSize = frames * THIS->_sourceAudioDescription.mBytesPerFrame;
    }

    struct complexInputDataProc_t inputDataProc = { .sourceBuffer = THIS->_scratchFloatBufferList };
    OSStatus result = AudioConverterFillComplexBuffer(THIS->_fromFloatConverter,
                                                      complexInputDataProc,
                                                      &inputDataProc,
                                                      &frames,
                                                      targetBuffer,
                                                      NULL);

    for ( int i=0; i<targetBuffer->mNumberBuffers; i++ ) {
      targetBuffer->mBuffers[i].mDataByteSize = priorDataByteSize;
    }

    if ( !checkResult(result, "AudioConverterConvertComplexBuffer") ) {
      return false;
    }
  } else {
    for ( int i=0; i<targetBuffer->mNumberBuffers; i++ ) {
      memcpy(targetBuffer->mBuffers[i].mData, sourceBuffers[i], frames * sizeof(float));
    }
  }

  return true;
}

bool AEFloatConverterFromFloatBufferList(AEFloatConverter* converter, AudioBufferList *sourceBuffer, AudioBufferList *targetBuffer, UInt32 frames) {
  assert(sourceBuffer->mNumberBuffers == converter->_floatAudioDescription.mChannelsPerFrame);

  float *sourceBuffers[sourceBuffer->mNumberBuffers];
  for ( int i=0; i<sourceBuffer->mNumberBuffers; i++ ) {
    sourceBuffers[i] = (float*)sourceBuffer->mBuffers[i].mData;
  }
  return AEFloatConverterFromFloat(converter, sourceBuffers, targetBuffer, frames);
}

static OSStatus complexInputDataProc(AudioConverterRef             inAudioConverter,
                                     UInt32                        *ioNumberDataPackets,
                                     AudioBufferList               *ioData,
                                     AudioStreamPacketDescription  **outDataPacketDescription,
                                     void                          *inUserData) {
  struct complexInputDataProc_t *arg = (struct complexInputDataProc_t*)inUserData;
  if ( !arg->sourceBuffer ) {
    return kNoMoreDataErr;
  }

  memcpy(ioData, arg->sourceBuffer, sizeof(AudioBufferList) + (arg->sourceBuffer->mNumberBuffers-1)*sizeof(AudioBuffer));
  arg->sourceBuffer = NULL;

  return noErr;
}
