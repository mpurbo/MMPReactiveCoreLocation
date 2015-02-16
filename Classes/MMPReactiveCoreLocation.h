//
//  MMPReactiveCoreLocation.h
//
//  The MIT License (MIT)
//  Copyright (c) 2014-2015 Mamad Purbo, purbo.org
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

#import "MMPLocationManager.h"
#import "MMPResourceTracker.h"

@interface MMPReactiveCoreLocation : NSObject<MMPResourceLifecycleHelper>

+ (instancetype)service;

// =============================================================================
// Settings
// =============================================================================

- (instancetype)pauseLocationUpdatesAutomatically;
- (instancetype)pauseLocationUpdatesManually;
- (instancetype)distanceFilter:(CLLocationDistance)distanceFilter;
- (instancetype)desiredAccuracy:(CLLocationAccuracy)desiredAccuracy;
- (instancetype)activityType:(CLActivityType)activityType;
// TODO: implement these settings?
/*
- (instancetype)locationAgeLimit:(NSTimeInterval)locationAgeLimit;
- (instancetype)timeout:(NSTimeInterval)timeout;
*/
- (instancetype)region:(CLRegion *)region;
- (instancetype)headingFilter:(CLLocationDegrees)headingFilter;
- (instancetype)headingOrientation:(CLDeviceOrientation)headingOrientation;
- (instancetype)shouldDisplayHeadingCalibration:(BOOL(^)(CLLocationManager *))block;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
- (instancetype)authorizeAlways;
- (instancetype)authorizeWhenInUse;
#endif

// =============================================================================
// Location signals
// =============================================================================

- (RACSignal *)locations;
- (RACSignal *)location;
- (RACSignal *)significantLocationChanges;
- (RACSignal *)significantLocationChange;

// =============================================================================
// Region monitoring signals
// =============================================================================

- (RACSignal *)regionStates;
- (RACSignal *)regionEvents;

// =============================================================================
// Heading update signals
// =============================================================================

- (RACSignal *)headingUpdates;

// =============================================================================
// Visit monitoring signals
// =============================================================================

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
- (RACSignal *)visits;
#endif

// =============================================================================
// General signals
// =============================================================================

- (RACSignal *)errors;
- (RACSignal *)authorizationStatus;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
- (RACSignal *)authorize;
#endif

- (void)stop;

@end
