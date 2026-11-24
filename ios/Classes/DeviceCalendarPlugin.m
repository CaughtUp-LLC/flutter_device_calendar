#import "DeviceCalendarPlugin.h"
#import <flutter_device_calendar/flutter_device_calendar-Swift.h>

@implementation DeviceCalendarPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftDeviceCalendarPlugin registerWithRegistrar:registrar];
}
@end
