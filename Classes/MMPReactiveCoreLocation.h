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
#import <CoreBluetooth/CoreBluetooth.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

#pragma mark - Constants

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

/**
 *  Error code signifying that the location service is unable to get location because of an error. 
 *  Use key "error" on userInfo to get the actual error.
 */
extern const NSInteger MMPRCLSignalErrorServiceFailure;

/**
 *  Location update type. Whether to use standard location or significant change.
 */
enum {
    MMPRCLLocationUpdateTypeStandard,
    MMPRCLLocationUpdateTypeSignificantChange
};
typedef NSInteger MMPRCLLocationUpdateType;

enum {
    MMPRCLLocationAuthorizationTypeAlways,
    MMPRCLLocationAuthorizationTypeWhenInUse
};
typedef NSInteger MMPRCLLocationAuthorizationType;

enum {
    MMPRCLBeaconSignalTypeMonitor,
    MMPRCLBeaconSignalTypeRange
};
typedef NSInteger MMPRCLBeaconSignalType;

/**
 *  Type of event produced by beacon signals.
 */
enum {
    
    /**
     *  Bluetooth peripheral state has just been updated.
     */
    MMPRCLBeaconEventTypePeripheralStateUpdated,
    
    /**
     *  Location manager's authorization status has just been updated.
     */
    MMPRCLBeaconEventTypeAuthorizationStatusUpdated,
    
    /**
     *  State of the beacon region has just been determined.
     */
    MMPRCLBeaconEventTypeRegionStateUpdated,
    
    /**
     *  Beacon(s) has just been ranged.
     */
    MMPRCLBeaconEventTypeRanged
};
typedef NSInteger MMPRCLBeaconEventType;

#pragma mark - Beacon event

/**
 *  Beacon event produced by beacon signals.
 */
@interface MMPRCLBeaconEvent : NSObject

/**
 *  Type of the event determining which property value is available.
 */
@property (nonatomic, readonly) MMPRCLBeaconEventType eventType;

/**
 *  Bluetooth peripheral state (available only when the eventType is MMPRCLBeaconEventTypePeripheralStateUpdated).
 */
@property (nonatomic, readonly) CBPeripheralManagerState peripheralState;

/**
 *  Location manager's authorization status (available only when the eventType is MMPRCLBeaconEventTypeAuthorizationStatusUpdated).
 */
@property (nonatomic, readonly) CLAuthorizationStatus authorizationStatus;

/**
 *  Beacon region status (available only when the eventType is MMPRCLBeaconEventTypeRegionStateUpdated).
 */
@property (nonatomic, readonly) CLRegionState regionState;

/**
 *  Beacon region with status updated (available only when the eventType is MMPRCLBeaconEventTypeRegionStateUpdated).
 */
@property (nonatomic, readonly) CLRegion *region;

/**
 *  CLBeacon objects that has been successfully ranged (available only when the eventType is MMPRCLBeaconEventTypeRanged).
 */
@property (nonatomic, readonly) NSArray *rangedBeacons;

/**
 *  Beacon region that has been successfully ranged  (available only when the eventType is MMPRCLBeaconEventTypeRanged).
 */
@property (nonatomic, readonly) CLBeaconRegion *rangedRegion;

@end

#pragma mark - Main class

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
 *  The default value is MMPRCLLocationUpdateTypeStandard.
 */
@property(assign, nonatomic) MMPRCLLocationUpdateType locationUpdateType;

/**
 *  Whether the CLLocationManager should request for "Always" or "WhenInUse" authorization. In iOS < 8 this 
 *  property will not be used. For iOS > 8, the default value is MMPRCLLocationAuthorizationTypeWhenInUse.
 */
@property(assign, nonatomic) MMPRCLLocationAuthorizationType locationAuthorizationType;

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

/**---------------------------------------------------------------------------------------
 * @name Global location signals
 *  ---------------------------------------------------------------------------------------
 */

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

/**---------------------------------------------------------------------------------------
 * @name One-time location signals
 *  ---------------------------------------------------------------------------------------
 */

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

/**
 *  Requests for a single location with specified parameters from a private CLLocationManager
 *  specially created for the signal, and wait until the specified timeout.
 *  The signal will own the CLLocationManager, start and stop it automatically.
 *  The signal returned will send next once before completing.
 *  Timeout will generate an error with error domain RACSignalErrorDomain
 *  and error code RACSignalErrorTimedOut.
 *
 *  @param pausesLocationUpdatesAutomatically see CLLocationManager documentation for the meaning of this parameter.
 *  @param distanceFilter                     see CLLocationManager documentation for the meaning of this parameter.
 *  @param desiredAccuracy                    see CLLocationManager documentation for the meaning of this parameter.
 *  @param activityType                       see CLLocationManager documentation for the meaning of this parameter.
 *  @param locationUpdateType                 Whether the CLLocationManager should use standard location update or significant change location update.
 *  @param locationAgeLimit                   How old the location should be (to determine whether the location is cached or not). By default it's 5 seconds.
 *  @param timeout                            Timeout in seconds. Set to 0 for no timeout.
 *
 *  @return One-time location signal with specified parameters.
 */
- (RACSignal *)singleLocationSignalWithPausesLocationUpdatesAutomatically:(BOOL)pausesLocationUpdatesAutomatically
                                                           distanceFilter:(CLLocationDistance)distanceFilter
                                                          desiredAccuracy:(CLLocationAccuracy)desiredAccuracy
                                                             activityType:(CLActivityType)activityType
                                                       locationUpdateType:(MMPRCLLocationUpdateType)locationUpdateType
                                                         locationAgeLimit:(NSTimeInterval)locationAgeLimit
                                                                  timeout:(NSTimeInterval)timeout;

/**---------------------------------------------------------------------------------------
 * @name Automatic location signals
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  Requests for a signal from a location manager with the specified update type. The location manager
 *  emitting location for this signal will be created, started, and stopped automatically by the signal.
 *
 *  @param locationUpdateType Whether the CLLocationManager should use standard location update or significant change location update.
 *
 *  @return Location signal producing locations with the specified update type.
 */
- (RACSignal *)autoLocationSignalWithLocationUpdateType:(MMPRCLLocationUpdateType)locationUpdateType;

/**
 *  Requests for a signal from a location manager with the specified parameters. The location manager
 *  emitting location for this signal will be created, started, and stopped automatically by the signal.
 *
 *  @param desiredAccuracy    Desired accuracy in meters.
 *  @param locationUpdateType Whether the CLLocationManager should use standard location update or significant change location update.
 *
 *  @return Location signal producing locations with parameters as specified.
 */
- (RACSignal *)autoLocationSignalWithAccuracy:(CLLocationAccuracy)desiredAccuracy
                           locationUpdateType:(MMPRCLLocationUpdateType)locationUpdateType;

/**
 *  Requests for a signal from a location manager with the specified parameters. The location manager 
 *  emitting location for this signal will be created, started, and stopped automatically by the signal.
 *
 *  @param pausesLocationUpdatesAutomatically see CLLocationManager documentation for the meaning of this parameter.
 *  @param distanceFilter                     see CLLocationManager documentation for the meaning of this parameter.
 *  @param desiredAccuracy                    see CLLocationManager documentation for the meaning of this parameter.
 *  @param activityType                       see CLLocationManager documentation for the meaning of this parameter.
 *  @param locationUpdateType                 Whether the CLLocationManager should use standard location update or significant change location update.
 *  @param locationAgeLimit                   How old the location should be (to determine whether the location is cached or not). By default it's 5 seconds.
 *  @param timeout                            Timeout in seconds. Set to 0 for no timeout.
 *
 *  @return Location signal producing locations with parameters as specified.
 */
- (RACSignal *)autoLocationSignalWithPausesLocationUpdatesAutomatically:(BOOL)pausesLocationUpdatesAutomatically
                                                         distanceFilter:(CLLocationDistance)distanceFilter
                                                        desiredAccuracy:(CLLocationAccuracy)desiredAccuracy
                                                           activityType:(CLActivityType)activityType
                                                     locationUpdateType:(MMPRCLLocationUpdateType)locationUpdateType
                                                       locationAgeLimit:(NSTimeInterval)locationAgeLimit;

/**
 *  Requests for a signal from a location manager with the specified parameters. The location manager
 *  emitting location for this signal will be created, started, and stopped automatically by the signal.
 *
 *  @param pausesLocationUpdatesAutomatically see CLLocationManager documentation for the meaning of this parameter.
 *  @param distanceFilter                     see CLLocationManager documentation for the meaning of this parameter.
 *  @param desiredAccuracy                    see CLLocationManager documentation for the meaning of this parameter.
 *  @param activityType                       see CLLocationManager documentation for the meaning of this parameter.
 *  @param locationUpdateType                 Whether the CLLocationManager should use standard location update or significant change location update.
 *  @param authorizationType                  Whether the CLLocationManager should use "Always" or "WhenInUse" authorization type.
 *  @param locationAgeLimit                   How old the location should be (to determine whether the location is cached or not). By default it's 5 seconds.
 *  @param timeout                            Timeout in seconds. Set to 0 for no timeout.
 *
 *  @return Location signal producing locations with parameters as specified.
 */
- (RACSignal *)autoLocationSignalWithPausesLocationUpdatesAutomatically:(BOOL)pausesLocationUpdatesAutomatically
                                                         distanceFilter:(CLLocationDistance)distanceFilter
                                                        desiredAccuracy:(CLLocationAccuracy)desiredAccuracy
                                                           activityType:(CLActivityType)activityType
                                                     locationUpdateType:(MMPRCLLocationUpdateType)locationUpdateType
                                              locationAuthorizationType:(MMPRCLLocationAuthorizationType)authorizationType
                                                       locationAgeLimit:(NSTimeInterval)locationAgeLimit;

/**---------------------------------------------------------------------------------------
 * @name iBeacon signals
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  Monitor beacon with specified UUID and identifier.
 *
 *  @param proximityUUID Beacon's UUID.
 *  @param identifier    Beacon's unique ID.
 *
 *  @return iBeacon signal for monitoring.
 */
- (RACSignal *)beaconMonitorWithProximityUUID:(NSUUID *)proximityUUID
                                   identifier:(NSString *)identifier;

/**
 *  Range beacon with specified UUID and identifier.
 *
 *  @param proximityUUID Beacon's UUID.
 *  @param identifier    Beacon's unique ID.
 *
 *  @return iBeacon signal for ranging.
 */
- (RACSignal *)beaconRangeWithProximityUUID:(NSUUID *)proximityUUID
                                 identifier:(NSString *)identifier;

/**
 *  iBeacon signal transmitting iBeacon-related events (MMPRCLBeaconEvent) for beacon
 *  with details as specified.
 *
 *  @param proximityUUID             Beacon's UUID.
 *  @param major                     Beacon's group ID.
 *  @param minor                     Beacon's specific ID.
 *  @param identifier                Beacon's unique ID.
 *  @param notifyOnEntry             Whether entrance to a beacon's region should generate an event.
 *  @param notifyOnExit              Whether exit from a beacon's region should generate an event.
 *  @param notifyEntryStateOnDisplay Whether beacon notifications are sent when the device’s display is on.
 *  @param beaconSignalType          Type of beacon signal (monitoring or ranging).
 *  @param autoStartOnStatusChange   Whether monitoring/ranging should be started/stopped automatically when bluetooth & location manager becoming available/unavailable.
 *
 *  @return iBeacon signal.
 */
- (RACSignal *)beaconWithProximityUUID:(NSUUID *)proximityUUID
                                 major:(NSNumber *)major
                                 minor:(NSNumber *)minor
                            identifier:(NSString *)identifier
                         notifyOnEntry:(BOOL)notifyOnEntry
                          notifyOnExit:(BOOL)notifyOnExit
             notifyEntryStateOnDisplay:(BOOL)notifyEntryStateOnDisplay
                      beaconSignalType:(MMPRCLBeaconSignalType)beaconSignalType
               autoStartOnStatusChange:(BOOL)autoStartOnStatusChange;
@end
