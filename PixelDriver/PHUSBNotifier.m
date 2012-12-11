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

#import "PHUSBNotifier.h"

#import "Utilities.h"
#import <IOKit/usb/IOUSBLib.h>
#import <IOKit/IOCFPlugIn.h>
#import <mach/mach_port.h>

NSString* const PHFT232ConnectionStateDidChangeNotification = @"PHFT232ConnectionStateDidChangeNotification";

// Most of this code ported from
// http://developer.apple.com/library/mac/#documentation/DeviceDrivers/Conceptual/USBBook/USBDeviceInterfaces/USBDevInterfaces.html#//apple_ref/doc/uid/TP40002645-TPXREF101

// FT232 USB IDs
static const SInt32 kFT232USBVendor = 1027;
static const SInt32 kFT232USBProduct = 24577;

void RawDeviceAdded(void *refCon, io_iterator_t iterator) {
  kern_return_t               kr;
  io_service_t                usbDevice;
  IOCFPlugInInterface         **plugInInterface = NULL;
  IOUSBDeviceInterface        **dev = NULL;
  HRESULT                     result;
  SInt32                      score;
  UInt16                      vendor;
  UInt16                      product;
  UInt16                      release;

  while ((usbDevice = IOIteratorNext(iterator))) {
    //Create an intermediate plug-in
    kr = IOCreatePlugInInterfaceForService(usbDevice,
                                           kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID,
                                           &plugInInterface, &score);
    //Don’t need the device object after intermediate plug-in is created
    kr = IOObjectRelease(usbDevice);
    if ((kIOReturnSuccess != kr) || !plugInInterface) {
      printf("Unable to create a plug-in (%08x)\n", kr);
      continue;
    }
    //Now create the device interface
    result = (*plugInInterface)->QueryInterface(plugInInterface,
                                                CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
                                                (LPVOID *)&dev);
    //Don’t need the intermediate plug-in after device interface
    //is created
    (*plugInInterface)->Release(plugInInterface);

    if (result || !dev) {
      printf("Couldn’t create a device interface (%08x)\n",
             (int) result);
      continue;
    }

    //Check these values for confirmation
    kr = (*dev)->GetDeviceVendor(dev, &vendor);
    kr = (*dev)->GetDeviceProduct(dev, &product);
    kr = (*dev)->GetDeviceReleaseNumber(dev, &release);
    if ((vendor != kFT232USBVendor) || (product != kFT232USBProduct)) {
      printf("Found unwanted device (vendor = %d, product = %d)\n",
             vendor, product);
      (void) (*dev)->Release(dev);
      continue;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:PHFT232ConnectionStateDidChangeNotification
                                                        object:nil];

    kr = (*dev)->Release(dev);
  }
}

void RawDeviceRemoved(void *refCon, io_iterator_t iterator) {
  kern_return_t   kr;
  io_service_t    object;

  while ((object = IOIteratorNext(iterator))) {
    kr = IOObjectRelease(object);
    if (kr != kIOReturnSuccess) {
      printf("Couldn’t release raw device object: %08x\n", kr);
      continue;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:PHFT232ConnectionStateDidChangeNotification
                                                        object:nil];
  }
}

@implementation PHUSBNotifier {
  IONotificationPortRef _notifyPort;
  io_iterator_t _rawAddedIter;
  io_iterator_t _rawRemovedIter;
}

- (id)init {
  if ((self = [super init])) {
    mach_port_t masterPort;
    kern_return_t kr;
    kr = IOMasterPort(MACH_PORT_NULL, &masterPort);
    if (kr || !masterPort) {
      PHAlert(@"Can't listen to USB port changes :(");
      self = nil;
      return self;
    }

    CFMutableDictionaryRef matchingDict = IOServiceMatching(kIOUSBDeviceClassName);
    if (nil == matchingDict) {
      PHAlert(@"Can't listen to USB port changes :(");
      mach_port_deallocate(mach_task_self(), masterPort);
      self = nil;
      return self;
    }

    CFDictionarySetValue(matchingDict, CFSTR(kUSBVendorName),
                         CFNumberCreate(kCFAllocatorDefault,
                                        kCFNumberSInt32Type, &kFT232USBVendor));
    CFDictionarySetValue(matchingDict, CFSTR(kUSBProductName),
                         CFNumberCreate(kCFAllocatorDefault,
                                        kCFNumberSInt32Type, &kFT232USBProduct));

    _notifyPort = IONotificationPortCreate(masterPort);
    CFRunLoopSourceRef runLoopSource = IONotificationPortGetRunLoopSource(_notifyPort);
    CFRunLoopAddSource([[NSRunLoop currentRunLoop] getCFRunLoop], runLoopSource, kCFRunLoopDefaultMode);

    matchingDict = (CFMutableDictionaryRef)CFRetain(matchingDict);
    matchingDict = (CFMutableDictionaryRef)CFRetain(matchingDict);

    kr = IOServiceAddMatchingNotification(_notifyPort,
                                          kIOMatchedNotification, matchingDict,
                                          RawDeviceAdded, NULL, &_rawAddedIter);
    RawDeviceAdded(NULL, _rawAddedIter);

    kr = IOServiceAddMatchingNotification(_notifyPort,
                                          kIOTerminatedNotification, matchingDict,
                                          RawDeviceRemoved, NULL, &_rawRemovedIter);
    RawDeviceRemoved(NULL, _rawRemovedIter);

    mach_port_deallocate(mach_task_self(), masterPort);
    masterPort = 0;
  }
  return self;
}

@end
