//
//  MMPReactiveCoreLocation.h
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
#import <ReactiveCocoa/ReactiveCocoa.h>

#define MMPRCL_LOCATION_AGE_LIMIT_DEFAULT 5.0
#define MMPRCL_LOCATION_TIMEOUT_DEFAULT -1

/**
 *  Error domain for errors produced by the library.
 */
extern NSString * const MMPRCLSignalErrorDomain;

/**
 *  Error code signifying that the location service is currently unavailable.
 */
extern const NSInteger MMPRCLSignalErrorServiceUnavailable;

enum {
    MMPRCLLocationUpdateTypeStandard,
    MMPRCLLocationUpdateTypeSignificantChange
};
typedef NSInteger MMPRCLLocationUpdateType;

/**
 *  Class providing location-related signals generated from CLLocationManager for use with ReactiveCocoa.
 */
@interface MMPReactiveCoreLocation : NSObject

/**
 *  Value of pausesLocationUpdatesAutomatically to be set to default CLLocationManager. Default to YES.
 *  See CLLocationManager documentation for more information on this property.
 */
@property(assign, nonatomic) BOOL pausesLocationUpdatesAutomatically;

/**
 *  Value of distanceFilter to be set to default CLLocationManager. Default to kCLDistanceFilterNone.
 *  See CLLocationManager documentation for more information on this property.
 */
@property(assign, nonatomic) CLLocationDistance distanceFilter;

/**
 *  Value of desiredAccuracy to be set to default CLLocationManager. Default to kCLLocationAccuracyBest.
 *  See CLLocationManager documentation for more information on this property.
 */
@property(assign, nonatomic) CLLocationAccuracy desiredAccuracy;

/**
 *  How long will manager wait for location update. Default to infinite(-1).
 *  Measured in seconds.
 */
@property(assign, nonatomic) NSTimeInterval defaultTimeout;

/**
 *  Default value for activityType to be set to default CLLocationManager.
 *  See CLLocationManager documentation for more information on this property.
 */
@property(assign, nonatomic) CLActivityType activityType;

/**
 *  Whether the CLLocationManager should use standard location update or significant change location update.
 */
@property(assign, nonatomic) MMPRCLLocationUpdateType locationUpdateType;

/**
 *  How old the location should be (to determine whether the location is cached or not). By default it's 5 seconds.
 */
@property(assign, nonatomic) NSTimeInterval locationAgeLimit;

/**
 *  Last known location retrieved from shared CLLocationManager.
 */
@property(readonly) CLLocation *lastKnownLocation;

/**
 *  This method is unavailable. Do not call this method directly. Use `instance` instead.
 *
 *  @return none
 */
+ (instancetype) alloc __attribute__((unavailable("alloc not available, call sharedInstance instead")));

/**
 *  This method is unavailable. Do not call this method directly. Use `instance` instead.
 *
 *  @return none
 */
- (instancetype) init __attribute__((unavailable("init not available, call sharedInstance instead")));

/**
 *  This method is unavailable. Do not call this method directly. Use `instance` instead.
 *
 *  @return none
 */
+ (instancetype) new __attribute__((unavailable("new not available, call sharedInstance instead")));

/**
 *  Gets the singleton object of this class.
 *
 *  @return Singleton object of this class.
 */
+ (instancetype)instance;

/**
 *  Starts updating locations using shared CLLocationManager managed by this class.
 */
- (void)start;

/**
 *  Stops updating locations using shared CLLocationManager managed by this class.
 */
- (void)stop;

/**
 *  Basic location signal that receives CLLocation from shared CLLocationManager managed by this class.
 *
 *  @return A location signal.
 */
- (RACSignal *)locationSignal;

/**
 *  Location signal that receives only CLLocation with specified accuracy. This signal receives
 *  CLLocation from shared CLLocationManager managed by this class.
 *
 *  @param desiredAccuracy Desired accuracy in meters.
 *
 *  @return A location signal with specified accuracy.
 */
- (RACSignal *)locationSignalWithAccuracy:(CLLocationAccuracy)desiredAccuracy;

/**
 *  Location signal that tries to wait until the specified accuracy is received. Once received
 *  the signal will be completed. Timeout will generate an error with error domain RACSignalErrorDomain
 *  and error code RACSignalErrorTimedOut. This signal receives
 *  CLLocation from shared CLLocationManager managed by this class.
 *
 *  @param desiredAccuracy Desired accuracy in meters.
 *  @param timeout         Timeout in seconds.
 *
 *  @return A location signal with specified accuracy and timeout.
 */
- (RACSignal *)locationSignalWithAccuracy:(CLLocationAccuracy)desiredAccuracy timeout:(NSTimeInterval)timeout;

/**
 *  Requests for a single location from a private CLLocationManager specially created for the signal.
 *  The signal will own the CLLocationManager, start and stop it automatically. The signal returned 
 *  will send next once before completing.
 *
 *  @return One-time location signal.
 */
- (RACSignal *)singleLocationSignal;

/**
 *  Requests for a single location with specified accuracy from a private CLLocationManager 
 *  specially created for the signal. The signal will own the CLLocationManager, start and stop it automatically. 
 *  The signal returned will send next once before completing.
 *
 *  @return One-time location signal with specified accuracy.
 */
- (RACSignal *)singleLocationSignalWithAccuracy:(CLLocationAccuracy)desiredAccuracy;

/**
 *  Requests for a single location with specified accuracy from a private CLLocationManager
 *  specially created for the signal, and wait until the specified timeout. 
 *  The signal will own the CLLocationManager, start and stop it automatically.
 *  The signal returned will send next once before completing.
 *  Timeout will generate an error with error domain RACSignalErrorDomain
 *  and error code RACSignalErrorTimedOut.
 *
 *  @param desiredAccuracy Desired accuracy in meters.
 *  @param timeout         Timeout in seconds.
 *
 *  @return One-time location signal with specified accuracy and timeout.
 */
- (RACSignal *)singleLocationSignalWithAccuracy:(CLLocationAccuracy)desiredAccuracy timeout:(NSTimeInterval)timeout;

@end
