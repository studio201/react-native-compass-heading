#import "CompassHeading.h"

#define kHeadingUpdated @"HeadingUpdated"


@implementation CompassHeading{
    CLLocationManager *locationManager;
    BOOL isObserving;
}

RCT_EXPORT_MODULE()


+ (BOOL)requiresMainQueueSetup
{
    return NO;
}

- (instancetype)init {
    if (self = [super init]) {
        isObserving = NO;

        if ([CLLocationManager headingAvailable]) {
            locationManager = [[CLLocationManager alloc] init];
            locationManager.delegate = self;
        }
        else {
            locationManager = nil;
            //NSLog(@"Heading not available");
        }
    }

    return self;
}

#pragma mark - RCTEventEmitter

- (NSArray<NSString *> *)supportedEvents {
    return @[kHeadingUpdated];
}

- (void)startObserving {
    isObserving = YES;
}

- (void)stopObserving {
    isObserving = NO;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    if (newHeading.headingAccuracy < 0) {
        return;
    }

    dispatch_sync(dispatch_get_main_queue(), ^{
        if(isObserving){
            [self sendEventWithName:kHeadingUpdated body:@{
                @"trueHeading": @(newHeading.trueHeading),
                @"magneticHeading": @(newHeading.magneticHeading),
                @"accuracy": @(newHeading.headingAccuracy)
            }];
        }
    });
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    //NSLog(@"AuthoriationStatus changed: %i", status);
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    //NSLog(@"Location manager failed: %@", error);
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager
{
    // return false;
    CLLocationDirection accuracy = [[manager heading] headingAccuracy];
    return accuracy <= 0.0f || (accuracy > locationManager.headingFilter);
}

#pragma mark - React

RCT_EXPORT_METHOD(start: (NSInteger) headingFilter
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    @try{
        locationManager.headingFilter = headingFilter;
        [locationManager startUpdatingHeading];
        resolve(@(YES));
    }
    @catch (NSException *exception) {
        reject(@"failed_start", exception.name, nil);
    }
}

RCT_EXPORT_METHOD(stop) {
    [locationManager stopUpdatingHeading];
}

RCT_EXPORT_METHOD(hasCompass:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    BOOL result = locationManager != nil ? YES : NO;
    resolve(@(result));
}

@end
