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

enum {
    MMPRCLLocationUpdateTypeStandard,
    MMPRCLLocationUpdateTypeSignificantChange
};
typedef NSInteger MMPRCLLocationUpdateType;

/**
 *  Class providing location-related signals generated from CLLocationManager for use with ReactiveCocoa.
 */
@interface MMPReactiveCoreLocation : NSObject

@property(assign, nonatomic) BOOL pausesLocationUpdatesAutomatically;
@property(assign, nonatomic) CLLocationDistance distanceFilter;
@property(assign, nonatomic) CLLocationAccuracy desiredAccuracy;
@property(assign, nonatomic) CLActivityType activityType;
@property(assign, nonatomic) MMPRCLLocationUpdateType locationUpdateType;

@property(readonly) CLLocation *lastKnownLocation;

// clue for improper use (produces compile time error)
+ (instancetype) alloc __attribute__((unavailable("alloc not available, call sharedInstance instead")));
- (instancetype) init __attribute__((unavailable("init not available, call sharedInstance instead")));
+ (instancetype) new __attribute__((unavailable("new not available, call sharedInstance instead")));

/**
 *  Gets the singleton object of this class.
 *
 *  @return Singleton object of this class.
 */
+ (instancetype)instance;

/**
 *  Starts the default CLLocationManager 
 */
- (void)start;
- (void)stop;

- (RACSignal *)locationSignal;

@end
