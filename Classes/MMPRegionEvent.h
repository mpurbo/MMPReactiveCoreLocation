//
//  MMPRegionEvent.h
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

typedef NS_ENUM(NSInteger, MMPRegionEventType) {
    MMPRegionEventTypeUnknown = 0,
    MMPRegionEventTypeRegionEnter,
    MMPRegionEventTypeRegionExit,
    MMPRegionEventTypeRegionStateDetermined,
    MMPRegionEventTypeRegionStartMonitoring,
    MMPRegionEventTypeRegionFailedMonitoring,
    MMPRegionEventTypeBeaconRanged,
    MMPRegionEventTypeBeaconFailedRanging
};

@interface MMPRegionEvent : NSObject

@property(readonly, nonatomic) MMPRegionEventType type;
@property(readonly, nonatomic) CLRegion *region;
@property(readonly, nonatomic) CLRegionState state;
@property(readonly, nonatomic) NSArray *beacons;
@property(readonly, nonatomic) NSError *error;

- (id)initWithType:(MMPRegionEventType)type forRegion:(CLRegion *)region;
- (id)initWithType:(MMPRegionEventType)type state:(CLRegionState)state forRegion:(CLRegion *)region;
- (id)initWithType:(MMPRegionEventType)type error:(NSError *)error forRegion:(CLRegion *)region;
- (id)initWithType:(MMPRegionEventType)type beacons:(NSArray *)beacons forRegion:(CLBeaconRegion *)region;

@end
