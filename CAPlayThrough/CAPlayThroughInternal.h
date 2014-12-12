
#include "CAPlayThrough.h"
#include "AEFloatConverter.h"

// we define the class here so that is is not accessible from any object aside from CAPlayThroughManager
class CAPlayThrough
{
public:
  CAPlayThrough(AudioDeviceID input, AudioDeviceID output);
  ~CAPlayThrough();

  OSStatus	Init(AudioDeviceID input, AudioDeviceID output);
  void		Cleanup();
  OSStatus	Start();
  OSStatus	Stop();
  Boolean		IsRunning();
  OSStatus	SetInputDeviceAsCurrent(AudioDeviceID in);
  OSStatus	SetOutputDeviceAsCurrent(AudioDeviceID out);

  AudioDeviceID GetInputDeviceID()	{ return mInputDevice.mID;	}
  AudioDeviceID GetOutputDeviceID()	{ return mOutputDevice.mID; }

  void postNotification();

private:
  OSStatus SetupGraph(AudioDeviceID out);
  OSStatus MakeGraph();

  OSStatus SetupAUHAL(AudioDeviceID in);
  OSStatus EnableIO();
  OSStatus CallbackSetup();
  OSStatus SetupBuffers();

  void ComputeThruOffset();

  static OSStatus InputProc(void *inRefCon,
                            AudioUnitRenderActionFlags *ioActionFlags,
                            const AudioTimeStamp *inTimeStamp,
                            UInt32				inBusNumber,
                            UInt32				inNumberFrames,
                            AudioBufferList *		ioData);

  static OSStatus OutputProc(void *inRefCon,
                             AudioUnitRenderActionFlags *ioActionFlags,
                             const AudioTimeStamp *inTimeStamp,
                             UInt32				inBusNumber,
                             UInt32				inNumberFrames,
                             AudioBufferList *	ioData);

  AudioUnit mInputUnit;

  AEFloatConverter *converter;
  float           **floatBuffers;

  AudioBufferList *mInputBuffer;
  AudioDevice mInputDevice, mOutputDevice;
  CARingBuffer *mBuffer;

  //AudioUnits and Graph
  AUGraph mGraph;
  AUNode mVarispeedNode;
  AudioUnit mVarispeedUnit;
  AUNode mOutputNode;
  AudioUnit mOutputUnit;
  
  //Buffer sample info
  Float64 mFirstInputTime;
  Float64 mFirstOutputTime;
  Float64 mInToOutSampleOffset;
};

