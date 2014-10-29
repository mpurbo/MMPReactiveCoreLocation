//
//  MMPLocationManager.h
//
//  The MIT License (MIT)
//  Copyright (c) 2014 Mamad Purbo, purbo.org
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "MMPRegionEvent.h"
#import "MMPRegionCommandEvent.h"
#import "MMPDeferEvent.h"

#define MMP_LOCATION_AGE_LIMIT_DEFAULT 5.0
#define MMP_LOCATION_TIMEOUT_DEFAULT -1

/**
 *  Error domain for errors produced by the library.
 */
extern NSString * const MMPLocationErrorDomain;

typedef NS_ENUM(NSInteger, MMPLocationErrorCode) {
    MMPLocationErrorServiceUnavailable = 1,
    MMPLocationErrorServiceFailure = 2,
    MMPLocationErrorServiceAlreadyStarted = 3
};

typedef NS_ENUM(NSInteger, MMPLocationEventType) {
    MMPLocationEventTypeUnknown = 0,
    MMPLocationEventTypePaused,
    MMPLocationEventTypeResumed
};

@interface MMPLocationManager : NSObject

@property(readonly, nonatomic) BOOL pausesLocationUpdatesAutomatically;
@property(readonly, nonatomic) CLLocationDistance distanceFilter;
@property(readonly, nonatomic) CLLocationAccuracy desiredAccuracy;
@property(readonly, nonatomic) NSTimeInterval timeout;
@property(readonly, nonatomic) CLActivityType activityType;
@property(readonly, nonatomic) NSTimeInterval locationAgeLimit;

@property(readonly, nonatomic) CLLocation *lastKnownLocation;

- (instancetype)pauseLocationUpdatesAutomatically;
- (instancetype)pauseLocationUpdatesManually;
- (instancetype)distanceFilter:(CLLocationDistance)distanceFilter;
- (instancetype)desiredAccuracy:(CLLocationAccuracy)desiredAccuracy;
- (instancetype)activityType:(CLActivityType)activityType;
- (instancetype)locationAgeLimit:(NSTimeInterval)locationAgeLimit;
- (instancetype)timeout:(NSTimeInterval)timeout;

- (instancetype)stop:(RACSignal *)stopSignal;
- (instancetype)defer:(RACSignal *)deferSignal;
- (instancetype)regionCommand:(RACSignal *)regionCommandSignal;

- (RACSignal *)errors;
- (RACSignal *)locations;
- (RACSignal *)location;
- (RACSignal *)locationEvents;

- (RACSignal *)significantLocationChanges;
- (RACSignal *)significantLocationChange;

- (instancetype)headingFilter:(CLLocationDegrees)headingFilter;
- (instancetype)headingOrientation:(CLDeviceOrientation)headingOrientation;
- (instancetype)shouldDisplayHeadingCalibration:(BOOL(^)(CLLocationManager *))block;

- (RACSignal *)headingUpdates;

- (RACSignal *)regionStates;
- (RACSignal *)regionEvents;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000

- (RACSignal *)visits;

- (instancetype)authorizeAlways;
- (instancetype)authorizeWhenInUse;

#endif

- (RACSignal *)authorizationStatus;

@end
