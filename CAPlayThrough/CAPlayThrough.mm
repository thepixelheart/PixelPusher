#include "CAPlayThroughInternal.h"

#import <Cocoa/Cocoa.h>

void CAPlayThrough::postNotification() {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"playthrough" object:nil];
}
